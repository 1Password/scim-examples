locals {
  # Create a VPC if vpc_id is not supplied
  create_vpc = var.vpc_id == null

  vpc_key = "default"

  vpc_id = !local.create_vpc ? var.vpc_id : local.vpc_key

  vpc_config = !local.create_vpc ? {} : {
    (local.vpc_key) = {
      cidr_block = var.vpc_cidr_block
      tags       = var.name_prefix == null ? {} : { Name = "${var.name_prefix}-vpc" }
    }
  }
}

data "aws_vpc" "this" {
  id = !local.create_vpc ? var.vpc_id : aws_vpc.this[local.vpc_id].id
}

resource "aws_vpc" "this" {
  for_each = local.vpc_config

  cidr_block = each.value.cidr_block

  tags = each.value.tags
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  filter {
    name   = "subnet-id"
    values = !local.create_vpc ? var.public_subnets : aws_subnet.public[*].id
  }
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "region-name"
    values = [var.aws_region]
  }
}

resource "aws_subnet" "public" {
  count = !local.create_vpc ? 0 : 2

  vpc_id            = data.aws_vpc.this.id
  cidr_block        = cidrsubnet(data.aws_vpc.this.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = var.name_prefix == null ? {} : {
    Name = format(
      "%s-subnet-public%d-%s:",
      var.name_prefix, (count.index + 1), data.aws_availability_zones.available.names[count.index]
    )
  }
}

resource "aws_internet_gateway" "igw" {
  for_each = aws_vpc.this

  vpc_id = data.aws_vpc.this.id

  tags = var.name_prefix == null ? {} : { Name = "${var.name_prefix}-${each.key}-igw" }
}

resource "aws_route_table" "rtb" {
  for_each = aws_internet_gateway.igw

  vpc_id = data.aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[each.key].id
  }

  tags = var.name_prefix == null ? {} : { Name = "${var.name_prefix}-${each.key}-rtb" }
}

resource "aws_route_table_association" "subnet_route_table" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.rtb[aws_vpc.this[aws_subnet.public[count.index].vpc_id].key].id
}

locals {
  # Get the parent domain from the domain name
  domain = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
}

data "aws_route53_zone" "zone" {
  for_each = toset([local.domain])

  name         = each.value
  private_zone = false
}

resource "aws_acm_certificate" "op_scim_bridge" {
  for_each = toset([var.domain_name])

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "op_scim_bridge" {
  for_each = aws_acm_certificate.op_scim_bridge

  certificate_arn         = aws_acm_certificate.op_scim_bridge[each.key].arn
  validation_record_fqdns = [for record in aws_route53_record.op_scim_bridge_validation : record.fqdn]

  provisioner "local-exec" {
    interpreter = ["echo"]
    command = var.using_route53 ? "Automatically validating your domain using Amazon Route 53..." : join("\n", [
      "Create this CNAME record to validate your domain:",
      jsonencode({
        for dvo in aws_acm_certificate.op_scim_bridge[each.key].domain_validation_options : dvo.domain_name => {
          name   = "${dvo.resource_record_name}."
          record = "${dvo.resource_record_value}."
        }
      })
    ])
  }

  timeouts {
    create = "72h" # Set to the ACM validation timeout 
  }
}

data "aws_acm_certificate" "cert" {
  domain = !var.wildcard_cert ? aws_acm_certificate.op_scim_bridge[var.domain_name].domain_name : "*.${local.domain}"
}

resource "aws_route53_record" "op_scim_bridge_validation" {
  for_each = var.using_route53 && !var.wildcard_cert ? {
    for dvo in aws_acm_certificate.op_scim_bridge[var.domain_name].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone[local.domain].id
}

resource "aws_security_group" "lb" {
  vpc_id      = data.aws_vpc.this.id
  description = "Restrict load balancer traffic for 1Password SCIM Bridge."

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb" {
  security_group_id = aws_security_group.lb.id

  description = "Allow ingress on port 443 from anywhere to the load balancer for 1Password SCIM Bridge."
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lb" {
  security_group_id = aws_security_group.lb.id

  description                  = "Restrict egress from the load balancer to only the ECS service."
  referenced_security_group_id = var.service_security_group_id
  from_port                    = 3002
  to_port                      = 3002
  ip_protocol                  = "tcp"
}

resource "aws_alb" "app" {
  name_prefix        = var.name_prefix
  load_balancer_type = "application"
  subnets            = data.aws_subnets.public.ids
  security_groups    = [aws_security_group.lb.id]
}

resource "aws_route53_record" "lb" {
  for_each = var.using_route53 ? toset([var.domain_name]) : toset([])

  zone_id = data.aws_route53_zone.zone[local.domain].id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_alb.app.dns_name
    zone_id                = aws_alb.app.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_target_group" "op_scim_bridge" {
  name_prefix = var.name_prefix
  port        = 3002
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.this.id

  health_check {
    matcher = "200,301,302"
    path    = "/ping"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  certificate_arn = data.aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.op_scim_bridge.arn
  }
}
