variable "name_prefix" {
  type        = string
  description = "A common prefix to apply to the names of all AWS resources."
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to apply to all respective AWS resources."
}

variable "container_definitions" {
  type = list(object({
    name    = optional(string)
    command = optional(list(string))
    environment = optional(list(object({
      name  = string
      value = string
    })))
  }))
}

variable "iam_role" {
  type        = string
  description = "The IAM role to which the policy to read the Google Workspace credentials should be attached."
}

variable "enabled" {
  type        = bool
  description = "Whether or not the module is enabled."
}

variable "actor" {
  type        = string
  description = "The email address of the administrator in Google Workspace that the service account is acting on behalf of."
}

variable "bridgeAddress" {
  type        = string
  description = "The URL of 1Password SCIM Bridge."
}
