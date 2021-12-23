terraform {
  required_version = ">= 0.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : "scim-bridge"
  domain      = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
  tags        = var.tags == {} ? var.tags : {
                  application = "1Password SCIM Bridge",
                  version     = trimprefix(jsondecode(file("task-definitions/scim.json"))[0].image, "1password/scim:v")
                }
}

# Use the default VPC or find the VPC by name
data "aws_vpc" "vpc" {
  default = var.vpc_name == "" ? true : false
  tags    = var.vpc_name != "" ? { Name = var.vpc_name } : {}
}

# Find the public subnets in the VPC
data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.vpc.id
  tags   = var.vpc_name != "" ? { SubnetTier = "public"} : {}
}

resource "aws_secretsmanager_secret" "scimsession" {
  name                    = format("%s-%s",local.name_prefix,"scimsession")
  # Allow `terraform destroy` to delete secret (hint: save your scimsession file in 1Password)
  recovery_window_in_days = 0

  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "scimsession_1" {
  secret_id     = aws_secretsmanager_secret.scimsession.id
  secret_string = base64encode(file("${path.module}/scimsession"))
}

resource "aws_cloudwatch_log_group" "scim-bridge" {
  name_prefix = local.name_prefix
  tags        = local.tags
}

resource "aws_ecs_cluster" "scim-bridge" {
  name = var.name_prefix == "" ? "scim-bridge" : format("%s-%s",local.name_prefix,"scim-bridge")

  tags = local.tags
}

resource "aws_ecs_task_definition" "scim-bridge" {
  family = var.name_prefix == "" ? "scim-bridge" : format("%s-%s",local.name_prefix,"scim-bridge")
  container_definitions = templatefile("task-definitions/scim.json",
    { secret_arn     = aws_secretsmanager_secret.scimsession.arn,
      aws_logs_group = aws_cloudwatch_log_group.scim-bridge.name,
      region         = var.aws_region
  })
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.scim-bridge.arn

  tags                     = local.tags
}

resource "aws_iam_role" "scim-bridge" {
  name               = format("%s-%s",local.name_prefix,"task-role")
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags               = local.tags
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "scim-bridge" {
  role       = aws_iam_role.scim-bridge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "scim" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.scimsession.arn,
    ]
  }
}

resource "aws_iam_role_policy" "scim_secret_policy" {
  name   = format("%s-%s",local.name_prefix,"secret_policy")
  role   = aws_iam_role.scim-bridge.id
  policy = data.aws_iam_policy_document.scim.json
}

resource "aws_ecs_service" "scim_bridge_service" {
  name             = format("%s-%s",local.name_prefix,"service")
  cluster          = aws_ecs_cluster.scim-bridge.id
  task_definition  = aws_ecs_task_definition.scim-bridge.arn
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  desired_count    = 1
  
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group_http.arn
    container_name   = aws_ecs_task_definition.scim-bridge.family
    container_port   = 3002
  }

  network_configuration {
    subnets          = data.aws_subnet_ids.subnets.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }

  tags             = local.tags

  depends_on       = [aws_lb_listener.listener_https]
}

resource "aws_alb" "scim-bridge-alb" {
  name               = format("%s-%s",local.name_prefix,"alb")
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.subnets.ids
  security_groups    = [aws_security_group.scim-bridge-sg.id]
  
  tags               = local.tags
}

# Create a security group for the load balancer:
resource "aws_security_group" "scim-bridge-sg" {
  vpc_id = data.aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags   = local.tags
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 3002
    to_port   = 3002
    protocol  = "tcp"
    # Only allowing traffic in from the load balancer security group
    security_groups = [aws_security_group.scim-bridge-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_lb_target_group" "target_group_http" {
  name        = "target-group-http"
  port        = 3002
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
  health_check {
    matcher = "200,301,302"
    path    = "/app"
  }

  tags        = local.tags
}

resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_alb.scim-bridge-alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = !var.wildcard_cert ? (
                        var.using_route53 ?
                          aws_acm_certificate_validation.scim_bridge_cert_validate[0].certificate_arn : aws_acm_certificate.scim_bridge_cert[0].arn
                        ) : data.aws_acm_certificate.wildcard_cert[0].arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_http.arn
  }
}

output "cloudwatch_log_group" {
  description = "Where you can find your SCIM bridge logs"
  value       = aws_cloudwatch_log_group.scim-bridge.name
}

output "loadbalancer_dns_name" {
  description = "The name of the load balancer to target in your DNS"
  value       = var.using_route53 ? null : aws_alb.scim-bridge-alb.dns_name
}

data "aws_acm_certificate" "wildcard_cert" {
  count  =  !var.wildcard_cert ? 0 : 1

  domain = "*.${local.domain}"
}

resource "aws_acm_certificate" "scim_bridge_cert" {
  count             = !var.wildcard_cert ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "zone" {
  count        = var.using_route53 ? 1 : 0

  name         = local.domain
  private_zone = false
}

resource "aws_acm_certificate_validation" "scim_bridge_cert_validate" {
  count                   = var.using_route53 && !var.wildcard_cert ? 1 : 0

  certificate_arn         = aws_acm_certificate.scim_bridge_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.scim_bridge_cert_validation : record.fqdn]
}


resource "aws_route53_record" "scim_bridge_cert_validation" {
  for_each = (
    var.using_route53 && !var.wildcard_cert ?
    {
      for dvo in aws_acm_certificate.scim_bridge_cert[0].domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    } : {}
  )

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone[0].id
}

resource "aws_route53_record" "scim_bridge" {
  count   = var.using_route53 ? 1 : 0

  zone_id = data.aws_route53_zone.zone[0].id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_alb.scim-bridge-alb.dns_name
    zone_id                = aws_alb.scim-bridge-alb.zone_id
    evaluate_target_health = true
  }
}

output "scim_bridge_url" {
  description = "The URL of your SCIM bridge"
  value       = "https://${var.domain_name}"
}
