variable "aws_region" {
  type        = string
  description = "The region of the AWS account where the 1Password SCIM bridge will be deployed."
}

variable "domain_name" {
  type        = string
  description = "The public DNS address pointing to your SCIM bridge."
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to apply to all respective AWS resources."
}

variable "name_prefix" {
  type        = string
  description = "A common prefix to apply to the names of all AWS resources."
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

variable "using_cloudflare" {
  type        = bool
  default     = true
  description = "Set to false to use an external DNS provider"
}

variable "cloudflare_zone_domain" {
  type        = string
  default     = ""
  description = "If using cloudflare, the zone to create DNS records in"
}

variable "log_retention_days" {
  type        = number
  description = "Specifies the number of days to retain log events in CloudWatch. The log is retained indefinitely whne set to 0."
}

variable "scimsession" {
  type        = string
  description = "String content of the scimsession file"
  sensitive   = true
}

# (For customers using Google Workspace participants)
variable "using_google_workspace" {
  type        = bool
  default     = false
  description = "Set to true to add Google Workspace configuration to 1Password SCIM bridge"
}
