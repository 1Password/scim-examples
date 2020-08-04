/*
The following LB configuration requires SSL certificate, It can to be created manually
this is prerequisite before applying this template.
Below code searches for ACM certificate issued to endpoint_url.domain.tld 
*/

data "aws_acm_certificate" "lb" {
  domain      = "${var.endpoint_url}.${var.domain}"
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

/*
  AWS Application load balancer.
  Load balancer distributes incoming HTTP(S) traffic between app EC2 instances. It also provides TLS termination.
*/
resource "aws_lb" "app_alb" {
  name                       = "${var.env}-${var.application}-alb"
  subnets                    = var.public_subnets
  security_groups            = [aws_security_group.app_lb.id]
  internal                   = false
  enable_deletion_protection = false
  idle_timeout               = 400
  load_balancer_type         = "application"
  ip_address_type            = "ipv4"

  // uncomment below access_logs to enable LB logs
  /* access_logs {
    bucket  = "${var.log_bucket}"
    prefix  = "${var.env}/${var.application}"
    enabled = true
  } */

  tags = merge(
    {
      Name = "${var.env}-${var.application}-alb"
    },
    local.tags
  )
}

// LB target group
resource "aws_lb_target_group" "app_tg" {
  name                 = "${var.env}-${var.application}-${var.scim_port}-tg"
  port                 = var.scim_port
  protocol             = "HTTP"
  vpc_id               = var.vpc
  deregistration_delay = 30
  target_type          = "instance"

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  health_check {
    interval            = 10
    path                = "/ping"
    port                = var.scim_port
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = merge(
    {
      Name = "${var.env}-${var.application}-tg"
    },
    local.tags
  )
}

// LB listener
resource "aws_lb_listener" "app_lb_list443" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.lb.arn

  default_action {
    target_group_arn = aws_lb_target_group.app_tg.arn
    type             = "forward"
  }
}

// LB security group.
resource "aws_security_group" "app_lb" {
  name_prefix = "${var.env}-${var.application}_lb"
  description = "Allow access to ${var.application}-lb on port 443"
  vpc_id      = var.vpc

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

  tags = merge(
    {
      Name = "${var.env}-${var.application}-lb-sg"
    },
    local.tags
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      name,
      name_prefix,
    ]
  }
}

/*
  Route53 record creates "A" record in the public DNS zone.
*/
resource "aws_route53_record" "app_lb" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = "${var.endpoint_url}.${data.aws_route53_zone.domain.name}"
  type    = "A"

  alias {
    name                   = lower(aws_lb.app_alb.dns_name)
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = false
  }
}
