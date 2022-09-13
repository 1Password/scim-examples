variable "name_prefix" {
  type        = string
  description = "A common prefix to apply to the names of all AWS resources."
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to apply to all respective AWS resources."
}

variable "iam_role" {
  type = object({
    name = string
  })
  description = "The IAM role to which the policy to read the Google Workspace credentials should be attached."
}

variable "enabled" {
  type        = bool
  description = "Whether or not the module is enabled."
}
