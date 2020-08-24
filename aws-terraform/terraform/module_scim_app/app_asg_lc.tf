// Autoscaling Group configuration
resource "aws_autoscaling_group" "asg" {
  name                      = "${aws_launch_configuration.lc.name}-asg"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_grace_period = "300"
  health_check_type         = var.asg_health_check_type
  force_delete              = false
  launch_configuration      = aws_launch_configuration.lc.name
  vpc_zone_identifier       = var.private_subnets
  target_group_arns         = [aws_lb_target_group.app_tg.arn]
  min_elb_capacity          = var.min_size
  wait_for_capacity_timeout = "15m"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-${var.application}"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

// Launch Configuration
resource "aws_launch_configuration" "lc" {
  name_prefix                 = "${var.env}-${var.application}-lc"
  image_id                    = var.ami
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.id
  associate_public_ip_address = false
  user_data                   = var.user_data

  lifecycle {
    create_before_destroy = true
  }
}
