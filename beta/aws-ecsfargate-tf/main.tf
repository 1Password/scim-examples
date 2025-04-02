# Configures the AWS provider with the specified region.
provider "aws" {
  region = var.region
}

# Ensures that either a scimsession file or ARN is provided for SCIM authentication.
resource "null_resource" "scimsession_validation" {
  lifecycle {
    precondition {
      condition     = var.scimsession_file != "" || var.scimsession_arn != ""
      error_message = "Either 'scimsession_file' or 'scimsession_arn' must be specified in terraform.tfvars."
    }
  }
}

# Validates Google Workspace configuration: if a credentials file is provided, an actor must be specified; ARNs alone are sufficient.
resource "null_resource" "workspace_validation" {
  lifecycle {
    precondition {
      condition     = var.workspace_credentials_file == "" || (var.workspace_credentials_file != "" && var.workspace_actor != "")
      error_message = "If 'workspace_credentials_file' is set, 'workspace_actor' must also be provided."
    }
  }
}

# Secrets Manager Resources

# Creates a Secrets Manager secret for the SCIM session file, if provided.
resource "aws_secretsmanager_secret" "scimsession_secret" {
  count       = var.scimsession_file != "" ? (fileexists(var.scimsession_file) ? 1 : 0) : 0
  name        = var.scimsession_secret_name
  description = "Stores the SCIM session content uploaded from the specified file."
}

# Sets the secret value for the SCIM session, if a file is provided.
resource "aws_secretsmanager_secret_version" "scimsession_secret_version" {
  count         = var.scimsession_file != "" ? (fileexists(var.scimsession_file) ? 1 : 0) : 0
  secret_id     = aws_secretsmanager_secret.scimsession_secret[0].id
  secret_string = file(var.scimsession_file)
}

# Creates a Secrets Manager secret for Google Workspace credentials, if a file is provided.
resource "aws_secretsmanager_secret" "workspace_credentials_secret" {
  count       = var.workspace_credentials_file != "" ? (fileexists(var.workspace_credentials_file) ? 1 : 0) : 0
  name        = coalesce(var.workspace_credentials_secret_name, "1password-scim-workspace-credentials-${random_string.secret_suffix.result}")
  description = "Stores Google Workspace credentials uploaded from the specified file."
}

# Sets the secret value for Google Workspace credentials, if a file is provided.
resource "aws_secretsmanager_secret_version" "workspace_credentials_secret_version" {
  count         = var.workspace_credentials_file != "" ? (fileexists(var.workspace_credentials_file) ? 1 : 0) : 0
  secret_id     = aws_secretsmanager_secret.workspace_credentials_secret[0].id
  secret_string = file(var.workspace_credentials_file)
}

# Creates a Secrets Manager secret for Google Workspace settings, if integration is enabled and no ARN is provided.
resource "aws_secretsmanager_secret" "workspace_settings_secret" {
  count       = var.workspace_settings_arn == "" && ((var.workspace_credentials_file != "" || var.workspace_credentials_arn != "") || var.workspace_actor != "") ? 1 : 0
  name        = coalesce(var.workspace_settings_secret_name, "1password-scim-workspace-settings-${random_string.secret_suffix.result}")
  description = "Stores Google Workspace settings, including the actor email and SCIM bridge URL."
}

# Sets the secret value for Google Workspace settings, if integration is enabled and no ARN is provided.
resource "aws_secretsmanager_secret_version" "workspace_settings_secret_version" {
  count         = var.workspace_settings_arn == "" && ((var.workspace_credentials_file != "" || var.workspace_credentials_arn != "") || var.workspace_actor != "") ? 1 : 0
  secret_id     = aws_secretsmanager_secret.workspace_settings_secret[0].id
  secret_string = jsonencode({
    "actor"         = var.workspace_actor
    "bridgeAddress" = aws_apigatewayv2_api.api_gateway.api_endpoint
  })
}

# Generates a random suffix for unique secret names when custom names are not specified.
resource "random_string" "secret_suffix" {
  length  = 8
  special = false
  upper   = false
}

# VPC and Networking Resources

# Creates a new VPC if an existing VPC ID is not provided.
resource "aws_vpc" "vpc" {
  count                = var.vpc_id == "" ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "scim-bridge-vpc" }
}

# Creates the first public subnet in the VPC, if a new VPC is being provisioned.
resource "aws_subnet" "public_subnet_1" {
  count             = var.vpc_id == "" ? 1 : 0
  vpc_id            = aws_vpc.vpc[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 12, 0)
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "public-subnet-1" }
}

# Creates the second public subnet in the VPC, if a new VPC is being provisioned.
resource "aws_subnet" "public_subnet_2" {
  count             = var.vpc_id == "" ? 1 : 0
  vpc_id            = aws_vpc.vpc[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 12, 1)
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = { Name = "public-subnet-2" }
}

# Attaches an internet gateway to the VPC, if a new VPC is being provisioned.
resource "aws_internet_gateway" "igw" {
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = { Name = "scim-bridge-igw" }
}

# Configures a route table for public access in the VPC, if a new VPC is being provisioned.
resource "aws_route_table" "route_table" {
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
  tags = { Name = "scim-bridge-route-table" }
}

# Associates the first public subnet with the route table, if a new VPC is being provisioned.
resource "aws_route_table_association" "public_subnet_1_association" {
  count          = var.vpc_id == "" ? 1 : 0
  subnet_id      = aws_subnet.public_subnet_1[0].id
  route_table_id = aws_route_table.route_table[0].id
}

# Associates the second public subnet with the route table, if a new VPC is being provisioned.
resource "aws_route_table_association" "public_subnet_2_association" {
  count          = var.vpc_id == "" ? 1 : 0
  subnet_id      = aws_subnet.public_subnet_2[0].id
  route_table_id = aws_route_table.route_table[0].id
}

# Security Group Resources

# Defines a security group for API Gateway traffic to the SCIM Bridge.
resource "aws_security_group" "api_gateway_sg" {
  name        = "api-gateway-sg"
  description = "Controls API Gateway traffic for the 1Password SCIM Bridge."
  vpc_id      = var.vpc_id == "" ? aws_vpc.vpc[0].id : var.vpc_id
}

# Defines a security group for ECS service traffic to the SCIM Bridge.
resource "aws_security_group" "scim_bridge_sg" {
  name        = "scim-bridge-sg"
  description = "Controls ECS service traffic for the 1Password SCIM Bridge."
  vpc_id      = var.vpc_id == "" ? aws_vpc.vpc[0].id : var.vpc_id
}

# Defines a security group for Redis traffic within the SCIM Bridge infrastructure.
resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Controls Redis traffic for the 1Password SCIM Bridge."
  vpc_id      = var.vpc_id == "" ? aws_vpc.vpc[0].id : var.vpc_id
}

# Allows egress from API Gateway to the SCIM Bridge on port 3002.
resource "aws_security_group_rule" "api_gateway_egress" {
  type                     = "egress"
  from_port                = 3002
  to_port                  = 3002
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api_gateway_sg.id
  source_security_group_id = aws_security_group.scim_bridge_sg.id
}

# Allows ingress to the SCIM Bridge from API Gateway on port 3002.
resource "aws_security_group_rule" "scim_bridge_ingress" {
  type                     = "ingress"
  from_port                = 3002
  to_port                  = 3002
  protocol                 = "tcp"
  security_group_id        = aws_security_group.scim_bridge_sg.id
  source_security_group_id = aws_security_group.api_gateway_sg.id
}

# Allows egress from the SCIM Bridge to Redis on port 6379.
resource "aws_security_group_rule" "scim_bridge_redis_egress" {
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.scim_bridge_sg.id
  source_security_group_id = aws_security_group.redis_sg.id
}

# Allows public egress from the SCIM Bridge for HTTPS traffic on port 443.
resource "aws_security_group_rule" "scim_bridge_public_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.scim_bridge_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allows ingress to Redis from the SCIM Bridge on port 6379.
resource "aws_security_group_rule" "redis_ingress" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redis_sg.id
  source_security_group_id = aws_security_group.scim_bridge_sg.id
}

# Allows public egress from Redis for HTTPS traffic on port 443 (e.g., to Docker Hub).
resource "aws_security_group_rule" "redis_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.redis_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ECS Cluster and Service Resources

# Defines the ECS cluster for running the SCIM Bridge and Redis services.
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "op-scim-bridge-cluster"
}

# Configures Fargate as the capacity provider for the ECS cluster.
resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity_providers" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# Creates a CloudWatch log group for ECS task logs.
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/op-scim-bridge"
}

# Defines the IAM role for ECS task execution with logging permissions.
resource "aws_iam_role" "execution_role" {
  name = "scim-bridge-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Retrieves the current AWS account ID for use in IAM policy ARNs.
data "aws_caller_identity" "current" {}

# Attaches a policy to the ECS execution role, granting permissions to write logs to the specified CloudWatch log group.
resource "aws_iam_role_policy" "execution_role_policy" {
  name   = "ECSLogs"
  role   = aws_iam_role.execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/op-scim-bridge:*"
    }]
  })
}

# Defines the IAM role for the SCIM Bridge task with Secrets Manager access.
resource "aws_iam_role" "scim_bridge_task_role" {
  name = "scim-bridge-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attaches a policy to the task role for accessing Secrets Manager secrets.
resource "aws_iam_role_policy" "scim_bridge_task_policy" {
  name   = "SecretAccess"
  role   = aws_iam_role.scim_bridge_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = concat(
        [var.scimsession_file != "" ? (fileexists(var.scimsession_file) ? aws_secretsmanager_secret.scimsession_secret[0].arn : var.scimsession_arn) : var.scimsession_arn],
        (var.workspace_credentials_file != "" || var.workspace_credentials_arn != "") || var.workspace_actor != "" ? [
          var.workspace_credentials_file != "" ? (fileexists(var.workspace_credentials_file) ? aws_secretsmanager_secret.workspace_credentials_secret[0].arn : var.workspace_credentials_arn) : var.workspace_credentials_arn,
          var.workspace_settings_arn != "" ? var.workspace_settings_arn : aws_secretsmanager_secret.workspace_settings_secret[0].arn
        ] : []
      )
    }]
  })
}

# Configures a private DNS namespace for service discovery in AWS Cloud Map.
resource "aws_service_discovery_private_dns_namespace" "service_discovery_namespace" {
  name        = "1password"
  description = "Private DNS namespace for 1Password SCIM Bridge service discovery."
  vpc         = var.vpc_id == "" ? aws_vpc.vpc[0].id : var.vpc_id
}

# Defines the Redis service discovery entry in AWS Cloud Map.
resource "aws_service_discovery_service" "redis_service" {
  name         = "redis"
  namespace_id = aws_service_discovery_private_dns_namespace.service_discovery_namespace.id
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.service_discovery_namespace.id
    dns_records {
      ttl  = 60
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

# Defines the SCIM Bridge service discovery entry in AWS Cloud Map.
resource "aws_service_discovery_service" "scim_bridge_service" {
  name         = "scim"
  namespace_id = aws_service_discovery_private_dns_namespace.service_discovery_namespace.id
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.service_discovery_namespace.id
    dns_records {
      ttl  = 60
      type = "SRV"
    }
  }
}

# Defines the ECS task definition for the Redis service.
resource "aws_ecs_task_definition" "redis_task_definition" {
  family                   = "op-scim-redis"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution_role.arn
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
  container_definitions = jsonencode([{
    name      = "redis"
    image     = "redis"
    user      = "redis:redis"
    command   = ["--maxmemory", "256mb", "--maxmemory-policy", "volatile-lru", "--save", ""]
    portMappings = [{ containerPort = 6379 }]
    healthCheck = {
      command     = ["CMD-SHELL", "redis-cli ping | grep PONG"]
      startPeriod = 5
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-region"        = var.region
        "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
        "awslogs-stream-prefix" = "ecs/op-scim"
      }
    }
  }])
}

# Defines the ECS task definition for the SCIM Bridge service, including secret mounting.
resource "aws_ecs_task_definition" "scim_bridge_task_definition" {
  family                   = "op-scim-bridge"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.provisioning_volume == "base" ? 256 : var.provisioning_volume == "high" ? 512 : 1024
  memory                   = var.provisioning_volume == "base" ? 512 : 1024
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.scim_bridge_task_role.arn
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
  volume {
    name = "secrets"
  }
  container_definitions = jsonencode([
    {
      name      = "mount-secrets"
      essential = false
      image     = "amazon/aws-cli"
      mountPoints = [{
        containerPath = "/aws"
        sourceVolume  = "secrets"
      }]
      environment = concat(
        [{
          name  = "SCIMSESSION_ARN"
          value = var.scimsession_file != "" ? (fileexists(var.scimsession_file) ? aws_secretsmanager_secret.scimsession_secret[0].arn : var.scimsession_arn) : var.scimsession_arn
        }],
        (var.workspace_credentials_file != "" || var.workspace_credentials_arn != "") || var.workspace_actor != "" ? [
          {
            name  = "WORKSPACE_CREDENTIALS_ARN"
            value = var.workspace_credentials_file != "" ? (fileexists(var.workspace_credentials_file) ? aws_secretsmanager_secret.workspace_credentials_secret[0].arn : var.workspace_credentials_arn) : var.workspace_credentials_arn
          },
          {
            name  = "WORKSPACE_SETTINGS_ARN"
            value = var.workspace_settings_arn != "" ? var.workspace_settings_arn : aws_secretsmanager_secret.workspace_settings_secret[0].arn
          }
        ] : []
      )
      entryPoint = ["/bin/bash", "-c"]
      command    = [join(" ", concat(
        ["aws secretsmanager get-secret-value --secret-id $SCIMSESSION_ARN --query SecretString --output text > scimsession"],
        (var.workspace_credentials_file != "" || var.workspace_credentials_arn != "") || var.workspace_actor != "" ? [
          "&& aws secretsmanager get-secret-value --secret-id $WORKSPACE_CREDENTIALS_ARN --query SecretString --output text > workspace-credentials.json",
          "&& aws secretsmanager get-secret-value --secret-id $WORKSPACE_SETTINGS_ARN --query SecretString --output text > workspace-settings.json"
        ] : []
      ))]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = var.region
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-stream-prefix" = "ecs/op-scim"
        }
      }
    },
    {
      name      = "scim"
      image     = "1password/scim:${var.scim_bridge_version}"
      user      = "opuser:opuser"
      portMappings = [{ containerPort = 3002 }]
      dependsOn = [{ containerName = "mount-secrets", condition = "SUCCESS" }]
      mountPoints = [{
        containerPath = "/home/opuser/.op"
        sourceVolume  = "secrets"
      }]
      environment = concat(
        [{ name = "OP_REDIS_URL", value = "redis://${aws_service_discovery_service.redis_service.name}.1password:6379" }],
        var.op_confirmation_interval != "" ? [{ name = "OP_CONFIRMATION_INTERVAL", value = var.op_confirmation_interval }] : []
      )
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = var.region
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-stream-prefix" = "ecs/op-scim"
        }
      }
    }
  ])
}

# Deploys the Redis service on ECS Fargate.
resource "aws_ecs_service" "redis_ecs_service" {
  name            = "redis-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.redis_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    assign_public_ip = true
    subnets          = var.vpc_id == "" ? [aws_subnet.public_subnet_1[0].id, aws_subnet.public_subnet_2[0].id] : var.public_subnets
    security_groups  = [aws_security_group.redis_sg.id]
  }
  service_registries {
    registry_arn   = aws_service_discovery_service.redis_service.arn
    container_name = "redis"
  }
}

# Deploys the SCIM Bridge service on ECS Fargate.
resource "aws_ecs_service" "scim_bridge_ecs_service" {
  name            = "scim-bridge-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.scim_bridge_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    assign_public_ip = true
    subnets          = var.vpc_id == "" ? [aws_subnet.public_subnet_1[0].id, aws_subnet.public_subnet_2[0].id] : var.public_subnets
    security_groups  = [aws_security_group.scim_bridge_sg.id]
  }
  service_registries {
    registry_arn   = aws_service_discovery_service.scim_bridge_service.arn
    container_name = "scim"
    container_port = 3002
  }
}

# API Gateway Resources

# Creates a VPC link for API Gateway to access the SCIM Bridge service.
resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = "op-scim-bridge"
  security_group_ids = [aws_security_group.api_gateway_sg.id]
  subnet_ids         = var.vpc_id == "" ? [aws_subnet.public_subnet_1[0].id, aws_subnet.public_subnet_2[0].id] : var.public_subnets
}

# Defines the HTTP API Gateway for external access to the SCIM Bridge.
resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "op-scim-bridge"
  protocol_type = "HTTP"
}

# Configures the integration between API Gateway and the SCIM Bridge service via VPC link.
resource "aws_apigatewayv2_integration" "api_gateway_integration" {
  api_id                 = aws_apigatewayv2_api.api_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.vpc_link.id
  integration_uri        = aws_service_discovery_service.scim_bridge_service.arn
  payload_format_version = "1.0"
}

# Sets up a default route for all requests to the SCIM Bridge through API Gateway.
resource "aws_apigatewayv2_route" "api_gateway_route" {
  api_id             = aws_apigatewayv2_api.api_gateway.id
  route_key          = "$default"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.api_gateway_integration.id}"
}

# Deploys the API Gateway with auto-deployment enabled for the default stage.
resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "$default"
  auto_deploy = true
}

# Data Sources

# Retrieves available AWS availability zones for subnet placement.
data "aws_availability_zones" "available" {
  state = "available"
}