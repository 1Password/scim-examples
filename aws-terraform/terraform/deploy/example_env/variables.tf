// aws provider and environment variables

data "aws_availability_zones" "available" {
  state = "available"
}

variable "type" {
  type        = string
  description = "deployment type (e.g: 'testing', 'staging', 'production')"
  default     = "testing" // CHANGE_ME
}

variable "region" {
  type        = string
  description = "AWS region where your application is to be deployed (e.g: 'us-east-1')"
  default     = "region" // CHANGE_ME
}

variable "aws-account" {
  type        = string
  description = "AWS account ID"
  default     = "123456789012" // CHANGE_ME
}

variable "scim_secret_name" {
  type        = string
  description = "the name of the secret created in the Secrets Manager"
  default     = "op-scim-example/scimsession" // CHANGE_ME
}

variable "application" {
  description = "application name"
  type        = string
  default     = "op-scim"
}

variable "env" {
  type        = string
  description = "environment name (e.g: 'op-scim')"
  default     = "op-scim"
}


// application vars:

variable "asg_health_check_type" {
  type        = string
  description = "health check type (e.g: ELB or EC2)"
  default     = "ELB"
}

variable "scim_port" {
  type        = string
  description = "op-scim app port number"
  default     = "3002"
}

variable "scim_repo" {
  type        = string
  description = "1Password SCIM bridge public Debian repository"
  default     = "deb https://apt.agilebits.com/op-scim/ stable op-scim"
}

variable "scim_user" {
  type        = string
  description = "unprivileged user to run op-scim service"
  default     = "op-scim"
}

variable "scim_group" {
  type        = string
  description = "unprivileged group to run op-scim service"
  default     = "nogroup"
}

variable "scim_path" {
  type        = string
  description = "op-scim working directory path (e.g: /var/lib/op-scim)"
  default     = "/var/lib/op-scim"
}

variable "scim_session_path" {
  type        = string
  description = "op-scim scimsession file path (e.g: /var/lib/op-scim/.op/scimsession)"
  default     = "/var/lib/op-scim/.op/scimsession"
}


// environment variables

variable "domain" {
  // public domain name used for this deployment
  default = "example.com" // CHANGE_ME
}

variable "endpoint_url" {
  // op-scim endpoint subdomain (https://op-scim-example.example.com)
  // ensure your Certificate Manager certificate can accept this subdomain
  type    = string
  default = "op-scim-example"
}

variable "log_bucket" {
  description = "Load Balancer log bucket"
  default     = "log bucket name" // CHANGE_ME (optional)
}

variable "vpc_cidr" {
  default = "10.1.1.0/24" // CHANGE_ME
}

variable "subnet_cidr" {
  type = map(any)

  default = {
    public = [
      "10.1.1.0/28",
      "10.1.1.16/28",
    ]
    private = [
      "10.1.1.128/28",
      "10.1.1.144/28",
    ]
  }
}

variable "instance_type" {
  type    = string
  description = "size of instance to deploy to ('t3.micro' is adequate for op-scim)"
  default = "t3.micro"
}

data "aws_ami" "ubuntu20" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

// cache variables:

variable "cache_url" {
  default = "redis://localhost:6379"
}

