// vpc, subnets, route tables, route53, igw, ngw
module "infra" {
  source = "../../module_scim_infra/"

  env         = "${var.env}"
  type        = "${var.type}"
  region      = "${var.region}"
  az          = "${data.aws_availability_zones.available.names}"
  subnet_cidr = "${var.subnet_cidr}"
  vpc_cidr    = "${var.vpc_cidr}"
  domain      = "${var.domain}"
  application = "${var.application}"
}

// asg, alb, app instances (asg), instance iam, instance and lb sg, public dns
module "scim-app" {
  source = "../../module_scim_app/"

  env                   = "${var.env}"                                     // tag
  type                  = "${var.type}"                                    // tag
  application           = "${var.application}"                             // tag
  region                = "${var.region}"
  aws-account           = "${var.aws-account}"
  az                    = "${data.aws_availability_zones.available.names}"
  log_bucket            = "${var.log_bucket}"
  domain                = "${var.domain}"                                  // public
  endpoint_url          = "${var.endpoint_url}"
  ami                   = "${data.aws_ami.ubuntu.id}"
  instance_type         = "${var.instance_type}"
  min_size              = 1
  max_size              = 1
  desired_capacity      = 1
  asg_health_check_type = "${var.asg_health_check_type}"
  scim_repo             = "${var.scim_repo}"
  scim_user             = "${var.scim_user}"
  scim_group            = "${var.scim_group}"
  scim_path             = "${var.scim_path}"
  scim_session_path     = "${var.scim_session_path}"
  scim_secret_name      = "${var.scim_secret_name}"
  vpc                   = "${module.infra.vpc}"
  private_subnets       = ["${module.infra.infra_private_subnets}"]
  public_subnets        = ["${module.infra.infra_public_subnets}"]
  cache_port            = "${var.cache_port}"
  cache_dns_name        = "${var.cache_name}"
}
