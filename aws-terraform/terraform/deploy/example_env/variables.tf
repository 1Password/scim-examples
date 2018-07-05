// aws provider and environment variables

data "aws_availability_zones" "available" {
  state = "available"
}

variable "env" {
  type        = "string"
  description = "environment name. For example, op-scim"
  default     = "op-scim"
}

variable "type" {
  type        = "string"
  description = "environment type. For example, development, staging, testing"
  default     = "development"
}

variable "region" {
  type        = "string"
  description = "AWS region where the application is deployed, for example 'us-east-2'"
  default     = "region"                                                                // CHANGE_IT
}

variable "aws-account" {
  type        = "string"
  description = "AWS account identifier"
  default     = "123456789012"           // CHANGE_IT
}

variable "application" {
  description = "application name"
  type        = "string"
  default     = "op-scim"
}

// application vars:
variable "asg_health_check_type" {
  type        = "string"
  description = "health check type ELB or EC2"
  default     = "ELB"
}

variable "scim_port" {
  type        = "string"
  description = "op-scim app port number"
  default     = "3002"
}

variable "scim_repo" {
  type        = "string"
  description = "1Password SCIM bridge public debian repo"
  default     = "deb https://apt.agilebits.com/op-scim/ stable op-scim"
}

variable "scim_user" {
  type        = "string"
  description = "Unprivileged user to run op-scim service"
  default     = "scim_user"
}

variable "scim_group" {
  type        = "string"
  description = "Unprivilaged group to run op-scim service"
  default     = "nogroup"
}

variable "scim_path" {
  type        = "string"
  description = "scim working directory path, example: /var/lib/op-scim"
  default     = "/var/lib/op-scim"
}

variable "scim_session_path" {
  type        = "string"
  description = "session path, example: /var/lib/op-scim/.op/scimsession"
  default     = "/var/lib/op-scim/.op/scimsession"
}

variable "scim_secret_name" {
  type        = "string"
  description = "the friendly name of the secret created in the secrets manager"
  default     = "op-scim-dev/scimsession"                                        // CHANGE_IT
}

// environment variables

variable "log_bucket" {
  description = "Load Balancer log bucket"
  default     = "bucket name"              // CHANGE_IT (optional)
}

variable "instance_type" {
  type    = "string"
  default = "t2.micro"
}

variable "vpc_cidr" {
  default = "10.1.1.0/24" // CHANGE_IT
}

variable "subnet_cidr" {
  type = "map"

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

variable "domain" {
  // public domain, make sure ACM certificate is ussed for under this name
  default = "example.com" // CHANGE_IT
}

variable "endpoint_url" {
  // op-scim endpoint url prefix, resulting fqdn will be endpoint_url.domain (https://endpoint_url.example.com)
  type    = "string"
  default = "op-scim"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] // Canonical
}

// cache variables:

variable "cache_port" {
  default = "6379"
}

variable "cache_name" {
  default = "localhost"
}
