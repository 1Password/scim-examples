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
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = local.tags
  }
}

locals {
  # Merge some defaults into any input tags
  tags = merge(var.tags, {
    application = "1Password SCIM Bridge"
    version     = var.scim_bridge_version
  })

  # A name prefix to use when a name value is strictly required
  name_prefix = var.name_prefix != null ? var.name_prefix : "op-scim-bridge"
}

locals {
  # `scimsession` credentials file
  scimsession_file       = fileset(path.root, "scimsession")                       # file path as set
  scimsession_file_found = length(data.local_sensitive_file.scimsession_file) == 1 # filename found
}

data "local_sensitive_file" "scimsession_file" {
  for_each = local.scimsession_file

  filename = each.value
}

resource "aws_secretsmanager_secret" "scimsession" {
  name_prefix             = var.name_prefix
  description             = "The scimsession credentials file for 1Password SCIM Bridge."
  recovery_window_in_days = 0

  lifecycle {
    precondition {
      condition = local.scimsession_file_found
      error_message = join("\n\n", [
        "The `scimsesion` credentials file was not found.",
        "Save the `scimsession` file from 1Password to the working directory:", abspath(path.root)
      ])
    }
  }
}

resource "aws_secretsmanager_secret_version" "scimsession" {
  for_each = data.local_sensitive_file.scimsession_file

  secret_id     = aws_secretsmanager_secret.scimsession.id
  secret_string = data.local_sensitive_file.scimsession_file[each.key].content
}

data "aws_iam_policy_document" "execution_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "op_scim_bridge" {
  name_prefix        = var.name_prefix
  assume_role_policy = data.aws_iam_policy_document.execution_trust_policy.json
  description        = "Task execution role for the ECS service for 1Password SCIM Bridge."
}

data "aws_iam_policy_document" "execution_policy" {
  statement {
    actions = [
      "events:PutRule",
      "events:PutTargets",
      "events:DescribeRule",
      "events:ListTargetsByRule",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "execution_policy" {
  name_prefix = var.name_prefix
  policy      = data.aws_iam_policy_document.execution_policy.json
  description = "Allow sending to CloudWatch Logs."
}

resource "aws_iam_role_policy_attachment" "op_scim_bridge" {
  role       = aws_iam_role.op_scim_bridge.name
  policy_arn = aws_iam_policy.execution_policy.arn
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "task_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name_prefix        = var.name_prefix
  assume_role_policy = data.aws_iam_policy_document.task_trust_policy.json
  description        = "Task role for 1Password SCIM Bridge."
}

data "aws_iam_policy_document" "scimsession" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.scimsession.arn]
  }
}

resource "aws_iam_policy" "scimsession" {
  name_prefix = var.name_prefix
  policy      = data.aws_iam_policy_document.scimsession.json
  description = "Allow reading the AWS secret for the scimsession credentials file for 1Password SCIM Bridge."
}

resource "aws_iam_role_policy_attachment" "task_role" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.scimsession.arn
}

module "network" {
  source = "./modules/network"

  name_prefix               = var.name_prefix
  tags                      = local.tags
  aws_region                = data.aws_region.current.name
  vpc_id                    = var.vpc_id
  vpc_cidr_block            = var.vpc_cidr_block
  public_subnets            = var.public_subnets
  service_security_group_id = aws_security_group.service.id
  domain_name               = var.domain_name
  using_route53             = var.using_route53
  wildcard_cert             = var.wildcard_cert
}

resource "aws_cloudwatch_log_group" "op_scim_bridge" {
  name_prefix       = var.name_prefix
  retention_in_days = var.log_retention_days
}

locals {
  # Construct base container definitions
  base_container_definitions = jsondecode(
    # Pass in template values to container definitions file
    templatefile(
      "${path.root}/task-definitions/scim.json", # file path
      {
        scim_bridge_version = var.scim_bridge_version                      # SCIM bridge version
        secret_arn          = aws_secretsmanager_secret.scimsession.arn    # AWS secret ARN for `scimsession` file
        aws_logs_group      = aws_cloudwatch_log_group.op_scim_bridge.name # CloudWatch log group
        region              = data.aws_region.current.name                 # AWS region
      }
  ))

  # Enable Google Workspace module if Workspace admin email is supplied
  using_google_workspace = var.google_workspace_actor != null
}

module "google_workspace" {
  count = local.using_google_workspace ? 1 : 0

  source = "./modules/google-workspace"

  name_prefix           = var.name_prefix
  tags                  = local.tags
  container_definitions = local.base_container_definitions
  iam_role              = aws_iam_role.task_role.name
  enabled               = local.using_google_workspace
  actor                 = var.google_workspace_actor
  bridgeAddress         = "https://${var.domain_name}"
}

locals {
  # Container definitions to pass to task definition  
  container_definitions = !local.using_google_workspace ? local.base_container_definitions : [ # default to base
    # If connecting to Google Workspace, merge properties from the Google Workspace module
    for container in local.base_container_definitions :
    # Only merge the designated secret mounting container
    container.name != "mount-secrets" ? container :
    # Merge with the base definition
    merge(container,
      merge( # Inner merge to ensure consistent type
        # Selected properties from the base container
        {
          command     = container.command
          environment = container.environment
        },
        # Secret mounting container from the Google Workspace module
        {
          for container in module.google_workspace[0].container_definitions :
          container.name => container
        }["mount-secrets"]
      )
    )
  ]
}

resource "aws_ecs_cluster" "op_scim_bridge" {
  name = "${local.name_prefix}-cluster"
}

resource "aws_ecs_task_definition" "op_scim_bridge" {
  family                = "op_scim_bridge"
  container_definitions = jsonencode(local.container_definitions)

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 1024
  cpu                      = 256
  execution_role_arn       = aws_iam_role.op_scim_bridge.arn
  task_role_arn            = aws_iam_role.task_role.arn

  volume {
    configure_at_launch = false
    name                = "secrets"
  }

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "op_scim_bridge" {
  name                  = "${local.name_prefix}-service" # "name" is required
  cluster               = aws_ecs_cluster.op_scim_bridge.id
  task_definition       = aws_ecs_task_definition.op_scim_bridge.arn
  launch_type           = "FARGATE"
  platform_version      = "1.4.0"
  desired_count         = 1
  wait_for_steady_state = true

  load_balancer {
    target_group_arn = module.network.target_group_arn
    container_name = lookup(
      { for container in local.container_definitions : split(":", container.image)[0] => container.name },
      "1password/scim"
    )
    container_port = 3002
  }

  network_configuration {
    subnets          = module.network.public_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.service.id]
  }
}

resource "aws_security_group" "service" {
  vpc_id      = module.network.vpc_id
  description = "Restrict ECS service traffic for 1Password SCIM Bridge."

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "service" {
  security_group_id = aws_security_group.service.id

  description                  = "Restrict ingress to the ECS service from only the load balancer."
  referenced_security_group_id = module.network.lb_security_group_id
  from_port                    = 3002
  to_port                      = 3002
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "service" {
  security_group_id = aws_security_group.service.id

  description = "Allow egress from the ECS service to anywhere on port 443."
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

moved {
  from = aws_secretsmanager_secret_version.scimsession
  to   = aws_secretsmanager_secret_version.scimsession["scimsession"]
}

# --- Moved to the "network" module ---
# Networking resources have been refactored into a separate module.

moved {
  from = aws_alb.op_scim_bridge
  to   = module.network.aws_alb.app
}

moved {
  from = aws_security_group.alb
  to   = module.network.aws_security_group.lb
}

moved {
  from = aws_lb_target_group.op_scim_bridge
  to   = module.network.aws_lb_target_group.op_scim_bridge
}

moved {
  from = aws_lb_listener.https
  to   = module.network.aws_lb_listener.https
}

moved {
  from = aws_acm_certificate.op_scim_bridge
  to   = module.network.aws_acm_certificate.op_scim_bridge
}

moved {
  from = aws_acm_certificate_validation.op_scim_bridge
  to   = module.network.aws_acm_certificate_validation.op_scim_bridge
}

moved {
  from = aws_route53_record.op_scim_bridge
  to   = module.network.aws_route53_record.lb
}

moved {
  from = aws_route53_record.op_scim_bridge_validation
  to   = module.network.aws_route53_record.op_scim_bridge_validation
}
