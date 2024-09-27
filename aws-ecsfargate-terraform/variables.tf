variable "scim_bridge_version" {
  type        = string
  description = "The container image tag for 1Password SCIM Bridge."
}

variable "aws_region" {
  type        = string
  description = "The region of the AWS account where the 1Password SCIM Bridge will be deployed."
  default     = null
}

variable "domain_name" {
  type        = string
  description = "The public DNS address pointing to your SCIM bridge."
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to apply to all respective AWS resources."
  default     = null
}

variable "name_prefix" {
  type        = string
  description = "A common prefix to apply to the names of all AWS resources."
  default     = null
}

variable "vpc_name" {
  type        = string
  description = "The name of an existing VPC to use."
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
