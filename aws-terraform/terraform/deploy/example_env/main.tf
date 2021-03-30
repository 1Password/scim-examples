// vpc, subnets, route tables, route53, igw, ngw
module "infra" {
  source = "../../module_scim_infra/"

  providers = {
    aws = aws.main // CHANGE_ME
  }

  env         = var.env
  type        = var.type
  region      = var.region
  az          = data.aws_availability_zones.available.names
  subnet_cidr = var.subnet_cidr
  vpc_cidr    = var.vpc_cidr
  domain      = var.domain
  application = var.application
}

// asg, alb, app instances (asg), instance iam, instance and lb sg, public dns
module "scim-app" {
  source = "../../module_scim_app/"

  providers = {
    aws = aws.main // CHANGE_ME
  }

  env                   = var.env
  type                  = var.type
  application           = var.application
  region                = var.region
  aws-account           = var.aws-account
  log_bucket            = var.log_bucket
  domain                = var.domain
  endpoint_url          = var.endpoint_url
  ami                   = data.aws_ami.ubuntu18.id
  instance_type         = var.instance_type
  min_size              = 1
  max_size              = 1
  desired_capacity      = 1
  asg_health_check_type = var.asg_health_check_type
  scim_port             = var.scim_port
  scim_secret_name      = var.scim_secret_name
  user_data             = data.template_cloudinit_config.app-config.rendered
  vpc                   = module.infra.vpc
  private_subnets       = module.infra.infra_private_subnets
  public_subnets        = module.infra.infra_public_subnets
}

// Set instance hostname
data "template_file" "hostname" {
  template = file("${path.module}/user_data/01-set-hostname.yml")

  vars = {
    fqdn = "${var.application}-${var.env}-${var.domain}"
  }
}

// Configure app environment
data "template_file" "environment" {
  template = file("${path.module}/user_data/02-environment.yml")

  vars = {
    REDIS               = var.cache_dns_name
    REDISPORT           = var.cache_port
    SCIM_USER           = var.scim_user
    SCIM_GROUP          = var.scim_group
    SCIM_PATH           = var.scim_path
    SCIM_SESSION_PATH   = var.scim_session_path
    SCIM_SESSION_SECRET = var.scim_secret_name
    SCIM_REPO           = var.scim_repo
    REGION              = var.region
  }
}

data "template_cloudinit_config" "app-config" {
  gzip          = true
  base64_encode = true

  // Set instance hostname
  part {
    content_type = "text/cloud-config"
    content      = data.template_file.hostname.rendered
  }

  // Configure app environment
  part {
    content_type = "text/cloud-config"
    content      = data.template_file.environment.rendered
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  // Add instance system (OS) user(s), if needed
  part {
    content_type = "text/cloud-config"
    content      = file("${path.module}/user_data/03-default-users.yml")
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
