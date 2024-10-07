variable "domain_name" {
  type        = string
  description = "The public DNS name that will point to the load balancer for your 1Password SCIM bridge deployment."
}

variable "scim_bridge_version" {
  type        = string
  description = "The container image tag for 1Password SCIM Bridge."
}

variable "aws_region" {
  type        = string
  description = "An AWS region where the provider will operate."
  default     = null
}

variable "aws_profile" {
  type        = string
  description = "An AWS profile name to use with the provider."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to apply to all respective AWS resources."
  default     = {}
}

variable "name_prefix" {
  type        = string
  description = "A common prefix to apply to the names of all AWS resources."
  default     = null
}

variable "vpc_id" {
  type        = string
  description = "The ID of an existing VPC to use."
  default     = null
}

variable "vpc_cidr_block" {
  type        = string
  description = "A CIDR range to use when creating a VPC."
  default     = null
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of public subnets spanning at least two availability zones."
  default     = null
}

variable "wildcard_cert" {
  type        = bool
  default     = false
  description = "Set to true to use an existing wildcard certificate in ACM for the load balancer."
}

variable "using_route53" {
  type        = bool
  default     = true
  description = "Set to false to use an external DNS provider"
}

variable "log_retention_days" {
  type        = number
  description = "Specifies the number of days to retain log events in CloudWatch. The log is retained indefinitely when set to 0."
  default     = 0
}

# For customers integrating with Google Workspace
variable "google_workspace_actor" {
  type        = string
  default     = null
  description = "The email address of the administrator in Google Workspace that the service account is acting on behalf of."
}
