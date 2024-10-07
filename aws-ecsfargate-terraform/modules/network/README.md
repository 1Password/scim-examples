# 1Password SCIM Bridge network module

This is a Terraform module to conditionally create or define network resources for 1Password SCIM Bridge, including:

- VPC
- public subnets
- internet gateway
- route tables
- load balancer
- security group for load balancer traffic
- DNS records
- ACM certificate

This module is expected to be called by the [root module](../../) and not intended to be used independently.
