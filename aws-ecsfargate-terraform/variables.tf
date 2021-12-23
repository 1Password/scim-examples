variable "aws_region" {
  type        = string
  description = "The region of the AWS account where the SCIM bridge will be deployed."
}

variable "domain_name" {
  type        = string
  description = "The public DNS name pointing to the 1Password SCIM bridge."
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to apply to all respective AWS resources."
}

variable "name_prefix" {
  type        = string
  description = "A default prefix to apply to the names of all AWS resources."
}

variable "vpc_name" {
  type        = string
  description = "The name of an existing VPC to use."
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
