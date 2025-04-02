variable "region" {
  description = "The AWS region where resources will be deployed (e.g., 'eu-west-1')."
  type        = string
}

variable "vpc_id" {
  description = "(Optional) ID of an existing VPC to use for your SCIM bridge. If empty, a new VPC and two public subnets will be created."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "A CIDR block for the VPC. Required if vpc_id is empty; ignored if specifying a vpc_id."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "(Optional) A list of two or more public subnet IDs in the specified VPC."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.public_subnets) == 0 || length(var.public_subnets) >= 2
    error_message = "Must be a list of at least two existing subnets associated with unique availability zones in the specified VPC, or an empty list."
  }
}

variable "provisioning_volume" {
  description = "The expected volume of provisioning activity: 'base' (<1,000 users), 'high' (up to 5,000), or 'very-high' (>5,000)."
  type        = string
  default     = "base"
  validation {
    condition     = contains(["base", "high", "very-high"], var.provisioning_volume)
    error_message = "Must be one of: base, high, very-high."
  }
}

variable "scimsession_file" {
  description = "Path to the scimsession file (e.g., './scimsession'). If set, its contents are stored in Secrets Manager and override scimsession_arn."
  type        = string
  default     = ""
}

variable "scimsession_arn" {
  description = "ARN of an existing Secrets Manager secret containing the scimsession content. Ignored if scimsession_file is set."
  type        = string
  sensitive   = true
  default     = ""
}

variable "scimsession_secret_name" {
  description = "Name of the Secrets Manager secret for storing scimsession content when using a file."
  type        = string
  default     = "scimsession"
}

variable "scim_bridge_version" {
  description = "The tag of the 1Password SCIM Bridge image to pull from Docker Hub."
  type        = string
  default     = "v2.9.9"
}

variable "op_confirmation_interval" {
  description = "Value for the OP_CONFIRMATION_INTERVAL environment variable in the SCIM Bridge container (in seconds, e.g., '300')."
  type        = string
  default     = ""
}

variable "workspace_credentials_file" {
  description = "Path to the workspace credentials file (e.g., './workspace-credentials.json'). If set, its contents are stored in Secrets Manager and override workspace_credentials_arn."
  type        = string
  default     = ""
}

variable "workspace_credentials_arn" {
  description = "ARN of an existing Secrets Manager secret containing the workspace credentials. Ignored if workspace_credentials_file is set."
  type        = string
  sensitive   = true
  default     = ""
}

variable "workspace_actor" {
  description = "The email address of a Google Workspace administrator that the service account authenticates as."
  type        = string
  default     = ""
}

variable "workspace_credentials_secret_name" {
  description = "(Optional) Name of the Secrets Manager secret for storing workspace credentials when using a file. If empty, a unique name will be generated."
  type        = string
  default     = ""
}

variable "workspace_settings_secret_name" {
  description = "(Optional) Name of the Secrets Manager secret for storing workspace settings. If empty, a unique name will be generated."
  type        = string
  default     = ""
}

variable "workspace_settings_arn" {
  description = "ARN of an existing Secrets Manager secret containing the Google Workspace settings (actor and bridge address). Ignored if workspace_credentials_file or workspace_actor is set to create a new secret."
  type        = string
  sensitive   = true
  default     = ""
}