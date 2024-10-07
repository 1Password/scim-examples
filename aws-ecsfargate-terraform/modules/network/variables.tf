variable "name_prefix" {
  type        = string
  description = "A common prefix to apply to the names of all AWS resources."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to apply to all respective AWS resources."
}

variable "aws_region" {
  type        = string
  description = "The AWS region for the VPC."
}

variable "vpc_id" {
  type        = string
  description = "The ID of an existing VPC to use."
  default     = null
}

variable "vpc_cidr_block" {
  type        = string
  description = "A CIDR block to use when creating a VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of public subnets spanning at least two availability zones."
  default     = null

  validation {
    condition     = var.vpc_id == null || var.public_subnets != null
    error_message = "Public subnets must be specified if a VPC is specified."
  }

  validation {
    condition     = var.public_subnets != null ? (length(var.public_subnets) >= 2) : true
    error_message = "At least two public subnets must be specified."
  }
}

variable "service_security_group_id" {
  type        = string
  description = "The ID of the security group for the service."
}

variable "domain_name" {
  type        = string
  description = "The public DNS address pointing to your SCIM bridge."
}

variable "wildcard_cert" {
  type        = bool
  default     = false
  description = "Set to true to use an existing wildcard certificate in ACM for the load balancer."
}

variable "using_route53" {
  type        = bool
  default     = true
  description = "Set to false to use an external DNS provider."
}
