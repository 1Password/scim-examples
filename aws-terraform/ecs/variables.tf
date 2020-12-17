variable "region" {
    type = string
    description = ""
    default = "us-east-1"
}

variable "domain_name" {
    type = string
    description = ""
}

variable "dns_zone_id" {
    type = string
    description = ""
}

variable "aws_logs_group" {
    type = string
    description = ""
    default = "/ecs/scim-bridge"
}