// Autoscaling Group configuration
resource "aws_autoscaling_group" "asg" {
  lifecycle {
    create_before_destroy = true
  }

  availability_zones        = ["${var.az}"]
  name                      = "${aws_launch_configuration.lc.name}-asg"
  desired_capacity          = "${var.desired_capacity}"
  min_size                  = "${var.min_size}"
  max_size                  = "${var.max_size}"
  health_check_grace_period = "300"
  health_check_type         = "${var.asg_health_check_type}"
  force_delete              = false
  launch_configuration      = "${aws_launch_configuration.lc.name}"
  vpc_zone_identifier       = ["${var.private_subnets}"]
  target_group_arns         = ["${aws_lb_target_group.app_tg.arn}"]

  tag {
    key                 = "env"
    value               = "${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "type"
    value               = "${var.type}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Application"
    value               = "${var.application}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-${var.application}"
    propagate_at_launch = true
  }
}

// Launch Configuration
resource "aws_launch_configuration" "lc" {
  name_prefix = "${var.application}-${var.env}-lc"

  lifecycle {
    create_before_destroy = true
  }

  image_id                    = "${var.ami}"
  instance_type               = "${var.instance_type}"
  security_groups             = ["${aws_security_group.app.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.app.id}"
  associate_public_ip_address = false

  user_data = "${data.template_cloudinit_config.app-config.rendered}"
}

// set instance hostname
data "template_file" "hostname" {
  template = "${file("${path.module}/data/user_data/01-set-hostname-by-instance-id.yml")}"

  vars {
    fqdn   = "${var.application}-${var.env}-${var.domain}"
  }
}

// 1. service environment file. 
// 2. download and decrypt session file.
data "template_file" "environment" {
  template = "${file("${path.module}/data/user_data/02-environment.yml")}"

  vars {
    REDIS               = "${var.cache_dns_name}"
    REDISPORT           = "${var.cache_port}"
    SCIM_USER           = "${var.scim_user}"
    SCIM_GROUP          = "${var.scim_group}"
    SCIM_PATH           = "${var.scim_path}"
    SCIM_SESSION_PATH   = "${var.scim_session_path}"
    SCIM_SESSION_SECRET = "${var.scim_secret_name}"
    REGION              = "${var.region}"
  }
}

data "template_cloudinit_config" "app-config" {
  gzip          = true
  base64_encode = true

  # Set hostname
  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.hostname.rendered}"
  }

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.environment.rendered}"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
