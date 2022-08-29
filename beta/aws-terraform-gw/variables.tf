variable "name_prefix" {
  type        = string
  description = "A common prefix to apply to the names of all AWS resources."
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to apply to all respective AWS resources."
}
