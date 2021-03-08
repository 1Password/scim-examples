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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default_vpc_subnets" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_secretsmanager_secret" "scimsession" {
  name = "scim-bridge-scimsession"
}

resource "aws_secretsmanager_secret_version" "scimsession_1" {
  secret_id     = aws_secretsmanager_secret.scimsession.id
  secret_string = base64encode(file("${path.module}/scimsession"))
}

resource "aws_cloudwatch_log_group" "scim-bridge" {
  name_prefix = "scim-bridge-logs"
}

resource "aws_ecs_cluster" "scim-bridge" {
  name = "scim-bridge"
}

resource "aws_ecs_task_definition" "scim-bridge" {
  family = "scim-bridge"
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
}

resource "aws_iam_role" "scim-bridge" {
  name               = "scim-bridge-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
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
  name   = "scim_secret_policy"
  role   = aws_iam_role.scim-bridge.id
  policy = data.aws_iam_policy_document.scim.json
}

resource "aws_ecs_service" "scim_bridge_service" {
  name             = "scim_bridge_service"
  cluster          = aws_ecs_cluster.scim-bridge.id
  task_definition  = aws_ecs_task_definition.scim-bridge.arn
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  desired_count    = 1
  depends_on       = [aws_lb_listener.listener_https]

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group_http.arn
    container_name   = aws_ecs_task_definition.scim-bridge.family
    container_port   = 3002
  }

  network_configuration {
    subnets          = data.aws_subnet_ids.default_vpc_subnets.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }
}

resource "aws_alb" "scim-bridge-alb" {
  name               = "scim-bridge-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default_vpc_subnets.ids
  security_groups    = [aws_security_group.scim-bridge-sg.id]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "scim-bridge-sg" {
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
}

resource "aws_lb_target_group" "target_group_http" {
  name        = "target-group-http"
  port        = 3002
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
  health_check {
    matcher = "200,301,302"
    path    = "/"
  }
}

resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_alb.scim-bridge-alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.scim_bridge_cert_validate.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_http.arn
  }
}

output "cloudwatch-log-group" {
  description = "Where you can find your scim-bridge logs"
  value       = aws_cloudwatch_log_group.scim-bridge.name
}

output "loadbalancer-dns-name" {
  description = "The Load balancer address to set in your DNS"
  value       = aws_alb.scim-bridge-alb.dns_name
}

resource "aws_acm_certificate" "scim_bridge_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "scim_bridge_cert_validate" { 
  certificate_arn         = aws_acm_certificate.scim_bridge_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.scim_bridge_cert_validation : record.fqdn]
}

/* If you are not using AWS Route 53 and AWS Certificate Manager for your DNS, 
   comment out below here */
resource "aws_route53_record" "scim_bridge_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.scim_bridge_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_route53_record" "scim_bridge" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_alb.scim-bridge-alb.dns_name
    zone_id                = aws_alb.scim-bridge-alb.zone_id
    evaluate_target_health = true
  }
}
