terraform {
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : "op-scim-bridge"
  domain      = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
  tags = merge(var.tags, {
    application = "1Password SCIM Bridge",
    version     = trimprefix(jsondecode(file("${path.module}/task-definitions/scim.json"))[0].image, "1password/scim:v")
  })

  # Enable Google Workspace module if Workspace admin email is supplied
  using_google_workspace = var.google_workspace_actor != null

  # Define base configuration from ./task-definitions/scim.json
  base_container_definitions_json = templatefile(
    "${path.module}/task-definitions/scim.json",
    {
      secret_arn     = aws_secretsmanager_secret.scimsession.arn,
      aws_logs_group = aws_cloudwatch_log_group.op_scim_bridge.name,
      region         = var.aws_region,
    }
  )

  # Split base config array into discrete container definitions
  base_scim_bridge_container_definition = jsondecode(local.base_container_definitions_json)[0]
  base_redis_container_definition       = jsondecode(local.base_container_definitions_json)[1]

  # Conditionally merge Google Workspace config
  scim_bridge_container_definition = !local.using_google_workspace ? local.base_scim_bridge_container_definition : merge(
    local.base_scim_bridge_container_definition,
    {
      #Add Google Workspace secrets to current list
      secrets = concat(
        local.base_scim_bridge_container_definition.secrets,
        module.google_workspace[0].secrets,
      )
    }
  )

  # Create local variable for merging in config to Redis container
  redis_container_definition = local.base_redis_container_definition

  # Combine discrete container definitions into list
  container_definitions = [
    local.scim_bridge_container_definition,
    local.redis_container_definition,
  ]
}

data "aws_vpc" "this" {
  # Use the default VPC or find the VPC by name if specified
  default = var.vpc_name == "" ? true : false
  tags    = var.vpc_name != "" ? { Name = var.vpc_name } : {}
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  # Find the public subnets in the VPC, or if the default VPC, use both
  tags = var.vpc_name != "" ? { SubnetTier = "public" } : {}

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

data "aws_iam_policy_document" "scimsession" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.scimsession.arn,
    ]
  }
}

data "aws_acm_certificate" "wildcard_cert" {
  count = !var.wildcard_cert ? 0 : 1

  domain = "*.${local.domain}"
}

data "aws_route53_zone" "zone" {
  count = var.using_route53 ? 1 : 0

  name         = local.domain
  private_zone = false
}

resource "aws_secretsmanager_secret" "scimsession" {
  name_prefix = local.name_prefix
  # Allow `terraform destroy` to delete secret (hint: save your scimsession file in 1Password)
  recovery_window_in_days = 0

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "scimsession" {
  secret_id     = aws_secretsmanager_secret.scimsession.id
  secret_string = filebase64("${path.module}/scimsession")
}

resource "aws_cloudwatch_log_group" "op_scim_bridge" {
  name_prefix       = local.name_prefix
  retention_in_days = var.log_retention_days

  tags = local.tags
}

resource "aws_ecs_cluster" "op_scim_bridge" {
  name = var.name_prefix == "" ? "op-scim-bridge" : format("%s-%s", local.name_prefix, "scim-bridge")

  tags = local.tags
}

resource "aws_ecs_task_definition" "op_scim_bridge" {
  family                = var.name_prefix == "" ? "op_scim_bridge" : format("%s_%s", local.name_prefix, "scim_bridge")
  container_definitions = jsonencode(local.container_definitions)

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 1024
  cpu                      = 256
  execution_role_arn       = aws_iam_role.op_scim_bridge.arn

  runtime_platform {
    cpu_architecture         = "ARM64"
    operating_system_family  = "LINUX"
  }

  tags = local.tags
}

resource "aws_iam_role" "op_scim_bridge" {
  name_prefix        = local.name_prefix
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "op_scim_bridge" {
  role       = aws_iam_role.op_scim_bridge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "scimsession" {
  name_prefix = local.name_prefix
  role        = aws_iam_role.op_scim_bridge.id
  policy      = data.aws_iam_policy_document.scimsession.json
}

resource "aws_ecs_service" "op_scim_bridge" {
  name             = format("%s_%s", local.name_prefix, "service")
  cluster          = aws_ecs_cluster.op_scim_bridge.id
  task_definition  = aws_ecs_task_definition.op_scim_bridge.arn
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  desired_count    = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.op_scim_bridge.arn
    container_name   = jsondecode(file("${path.module}/task-definitions/scim.json"))[0].name
    container_port   = 3002
  }

  network_configuration {
    subnets          = data.aws_subnets.public.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.service.id]
  }

  tags = local.tags

  depends_on = [aws_lb_listener.https]
}

resource "aws_alb" "op_scim_bridge" {
  name               = var.name_prefix == "" ? "op-scim-bridge-alb" : format("%s-%s", local.name_prefix, "alb")
  load_balancer_type = "application"
  subnets            = data.aws_subnets.public.ids
  security_groups    = [aws_security_group.alb.id]

  tags = local.tags
}

resource "aws_security_group" "alb" {
  # Create a security group for the load balancer
  vpc_id = data.aws_vpc.this.id
  # Allow HTTPS traffic to the load balancer from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Restrict outgoing traffic from the load balancer to the ECS service
  egress {
    from_port   = 3002
    to_port     = 3002
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  tags = local.tags
}

resource "aws_security_group" "service" {
  # Create a security group for the service
  vpc_id = data.aws_vpc.this.id

  # Restrict incoming traffic to the service from the load balancer security group
  ingress {
    from_port       = 3002
    to_port         = 3002
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow HTTPS traffic from the service to anywhere (to allow TCP traffic to 1Password servers)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_lb_target_group" "op_scim_bridge" {
  name        = var.name_prefix == "" ? "op-scim-bridge-tg" : format("%s-%s", local.name_prefix, "tg")
  port        = 3002
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.this.id
  health_check {
    matcher = "200,301,302"
    path    = "/app"
  }

  tags = local.tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.op_scim_bridge.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"

  certificate_arn = !var.wildcard_cert ? (
    var.using_route53 ?
    aws_acm_certificate_validation.op_scim_bridge[0].certificate_arn : aws_acm_certificate.op_scim_bridge[0].arn
  ) : data.aws_acm_certificate.wildcard_cert[0].arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.op_scim_bridge.arn
  }
}

resource "aws_acm_certificate" "op_scim_bridge" {
  count = !var.wildcard_cert ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "op_scim_bridge" {
  count = var.using_route53 && !var.wildcard_cert ? 1 : 0

  certificate_arn         = aws_acm_certificate.op_scim_bridge[0].arn
  validation_record_fqdns = [for record in aws_route53_record.op_scim_bridge_validation : record.fqdn]
}


resource "aws_route53_record" "op_scim_bridge_validation" {
  for_each = (
    var.using_route53 && !var.wildcard_cert ?
    {
      for dvo in aws_acm_certificate.op_scim_bridge[0].domain_validation_options : dvo.domain_name => {
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

resource "aws_route53_record" "op_scim_bridge" {
  count = var.using_route53 ? 1 : 0

  zone_id = data.aws_route53_zone.zone[0].id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_alb.op_scim_bridge.dns_name
    zone_id                = aws_alb.op_scim_bridge.zone_id
    evaluate_target_health = true
  }
}

module "google_workspace" {
  count = local.using_google_workspace ? 1 : 0

  source = "./modules/google-workspace"

  name_prefix   = local.name_prefix
  tags          = local.tags
  iam_role      = aws_iam_role.op_scim_bridge
  enabled       = local.using_google_workspace
  actor         = var.google_workspace_actor
  bridgeAddress = "https://${var.domain_name}"
}

moved {
  from = aws_secretsmanager_secret_version.scimsession_1
  to   = aws_secretsmanager_secret_version.scimsession
}
