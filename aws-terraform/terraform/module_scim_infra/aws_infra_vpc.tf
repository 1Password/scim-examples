/*
  VPC
*/
resource "aws_vpc" "infra" {
  cidr_block           = "${var.vpc_cidr}"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Application = "${var.application}"
    env         = "${var.env}"
    type        = "${var.type}"
    Name        = "${var.env}-${var.application}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.infra.id}"

  tags {
    Application = "${var.application}"
    env         = "${var.env}"
    type        = "${var.type}"
    Name        = "${var.env}-${var.application}-igw"
  }
}

resource "aws_vpc_dhcp_options" "infra_dhcp" {
  domain_name         = "${var.application}-${var.env}.int"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags {
    Application = "${var.application}"
    env         = "${var.env}"
    type        = "${var.type}"
    Name        = "${var.env}-${var.application}-dhcpopt"
  }
}

resource "aws_vpc_dhcp_options_association" "infra_dhcp" {
  vpc_id          = "${aws_vpc.infra.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.infra_dhcp.id}"
}
