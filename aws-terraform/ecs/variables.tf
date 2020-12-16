variable "region" {
    type = string
    description = ""
    default = "us-east-1"
}

variable "prefix" {
    type = string
    description = ""
    default = "scim-bridge"
}

variable "secret_arn" {
    type = string
    description = ""
}

variable "domain_name" {
    type = string
    description = ""
}

variable "dns_zone_id" {
    type = string
    description = ""
    default = "Z3V3UMKDNQGJ7A"
}

variable "aws_logs_group" {
    type = string
    description = ""
    default = "/ecs/scim-bridge"
}