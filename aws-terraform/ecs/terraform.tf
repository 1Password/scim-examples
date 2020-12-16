provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

resource "aws_ecs_cluster" "scim-bridge" {
  name = "scim-bridge"
}

resource "aws_ecs_task_definition" "scim-bridge" {
  family                   = "scim-bridge"
  container_definitions    =  templatefile("task-definitions/scim.json", 
                              { secret_arn = var.secret_arn, 
                                aws_logs_group = var.aws_logs_group, 
                                region = var.region
                              })
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole-scim-bridge.arn
}

resource "aws_iam_role" "ecsTaskExecutionRole-scim-bridge" {
  name               = "ecsTaskExecutionRole-scim-bridge"
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

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy-scim-bridge" {
  role       = aws_iam_role.ecsTaskExecutionRole-scim-bridge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "scim_secret_policy" {
  name = "scim_secret_policy"
  role = aws_iam_role.ecsTaskExecutionRole-scim-bridge.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue"
        ],
        "Resource": [
          "${var.secret_arn}"
        ]
      }
    ]
  }
  EOF
}

resource "aws_ecs_service" "scim_bridge_service" {
  name            = "scim_bridge_service"
  cluster         = aws_ecs_cluster.scim-bridge.id
  task_definition = aws_ecs_task_definition.scim-bridge.arn
  launch_type     = "FARGATE"
  platform_version = "1.4.0"
  desired_count   = 1 
  depends_on      = [aws_lb_listener.listener_https]

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group_http.arn 
    container_name   = aws_ecs_task_definition.scim-bridge.family
    container_port   = 3002
  }

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id, aws_default_subnet.default_subnet_c.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }
}

resource "aws_alb" "scim-bridge-alb" {
  name               = "scim-bridge-alb"
  load_balancer_type = "application"
  subnets = [
    aws_default_subnet.default_subnet_a.id,
    aws_default_subnet.default_subnet_b.id,
    aws_default_subnet.default_subnet_c.id
  ]
  security_groups = [aws_security_group.scim-bridge-sg.id]
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
    from_port = 0
    to_port   = 0
    protocol  = "-1"
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
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_alb.scim-bridge-alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.scim_bridge_cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_http.arn
  }
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "${var.region}a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "${var.region}b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "${var.region}c"
}

resource "aws_acm_certificate" "scim_bridge_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

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
  zone_id         = var.dns_zone_id
}

resource "aws_route53_record" "scim_bridge" {
  zone_id = var.dns_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_alb.scim-bridge-alb.dns_name
    zone_id                = aws_alb.scim-bridge-alb.zone_id
    evaluate_target_health = true
  }
}