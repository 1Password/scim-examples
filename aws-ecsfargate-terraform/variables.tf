variable "aws_region" {
  type        = string
  description = ""
}

variable "domain_name" {
  type        = string
  description = ""
}

variable "tags" {
  type        = map(string)
  description = ""
}

variable "name_prefix" {
  type        = string
  description = ""
}

variable "vpc_name" {
  type        = string
  description = ""
}

variable "wildcard_cert" {
  type        = bool
  default     = false
  description = ""
}

variable "using_route53" {
  type        = bool
  default     = true
  description = ""
}
