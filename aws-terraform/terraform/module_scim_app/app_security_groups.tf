/*
  instance security group.
  Allows access from load balancer on port 80.
*/
resource "aws_security_group" "app" {
  name_prefix = "${var.env}-${var.application}-sg"
  description = "Allow access from load balancer"
  vpc_id      = var.vpc

  ingress {
    from_port       = var.scim_port
    to_port         = var.scim_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app_lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.env}-${var.application}-sg"
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
