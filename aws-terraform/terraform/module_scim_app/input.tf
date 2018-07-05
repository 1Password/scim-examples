variable "env" {
  type        = "string"
  description = "environment name. For example, op-scim"
}

variable "type" {
  type        = "string"
  description = "environment type. For example, development, staging, testing"
}

variable "az" {
  type        = "list"
  description = "A list of AWS Availability Zones where the application should be deployed"
}

variable "region" {
  type        = "string"
  description = "AWS region where the application is deployed, for example 'us-west-1'"
}

variable "aws-account" {
  type        = "string"
  description = "AWS account identifier"
}

variable "application" {
  description = "application name"
  type        = "string"
}

// app vars
variable "instance_type" {
  description = "Instance type for scim app"
  type        = "string"
}

variable "min_size" {
  type        = "string"
  description = "Minimum number of instances in the autoscaling group"
}

variable "max_size" {
  type        = "string"
  description = "Maximum number of instances in the autoscaling group"
}

variable "desired_capacity" {
  type        = "string"
  description = "The number of Amazon EC2 instances that should be running in the group."
}

variable "asg_health_check_type" {
  type        = "string"
  description = "ELB or EC2"
}

variable "scim_port" {
  type        = "string"
  description = "scim app port number"
}

variable "scim_repo" {
  type        = "string"
  description = "debian repo"
  default     = "deb https://apt.agilebits.com/op-scim/ stable op-scim"
}

variable "scim_user" {
  type        = "string"
  description = "unprivileged user"
}

variable "scim_group" {
  type        = "string"
  description = "unprivilaged group"
}

variable "scim_path" {
  type        = "string"
  description = "scim path, example: /var/lib/op-scim"
}

variable "scim_session_path" {
  type        = "string"
  description = "session path, example: /var/lib/op-scim/.op/scimsession"
}

variable "scim_secret_name" {
  type        = "string"
  description = "the friendly name of the secret created in the secrets manager"
}

// vpc vars

variable "log_bucket" {
  type = "string"
}

variable "vpc" {
  description = "vpc ID"
}

variable "domain" {
  type = "string"
}

variable "endpoint_url" {
  type = "string"
}

variable "private_subnets" {
  description = ""
  type        = "list"
}

variable "public_subnets" {
  description = ""
  type        = "list"
}

data "aws_route53_zone" "domain" {
  name = "${var.domain}."
}

variable "ami" {
  type        = "string"
  description = "Identifier of the image used to create the instance"
}

// cache vars:

variable "cache_port" {
  description = "default 6379"
}

variable "cache_dns_name" {
  description = "cache internal dns name"
}
