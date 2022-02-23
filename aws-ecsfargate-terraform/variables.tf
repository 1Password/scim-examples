variable "domain_name" {
  type        = string
  description = "The public DNS address pointing to your SCIM bridge."
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to apply to all respective AWS resources."
  default     = {}
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

variable "using_route53" {
  type        = bool
  default     = true
  description = "Set to false to use an external DNS provider"
}

variable "log_retention_days" {
  type        = number
  description = "Specifies the number of days to retain log events in CloudWatch. Set to the default of 0, the log is retained indefinitely."
}

variable "scimsession_arn" {
  type        = string
  description = "ARN of the secret storing the scimsession file."
}

variable "subnet_name" {
  type        = string
  description = "Regular expression for the Name tag to search for subnet ids."
}

variable "ecs_task_memory" {
  type        = number
  description = "Memory value to set in the task definition."
  default     = 512
}

variable "ecs_task_cpu" {
  type        = number
  description = "CPU value to set in the task definition."
  default     = 256
}
