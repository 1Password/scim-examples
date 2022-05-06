// aws provider and environment variables
provider "aws" {}

variable "env" {
  type        = string
  description = "environment name"
}

variable "type" {
  type        = string
  description = "environment name. For example, op-scim"
}

variable "az" {
  type        = list(string)
  description = "A list of AWS Availability Zones where the application should be deployed"
}

variable "region" {
  type        = string
  description = "AWS region where the application is deployed, for example 'us-west-1'"
}

variable "application" {
  description = "application name"
  type        = string
}

// vpc vars

variable "subnet_cidr" {
  type = map(any)
}

variable "vpc_cidr" {
  type = string
}

variable "domain" {
  type = string
}
