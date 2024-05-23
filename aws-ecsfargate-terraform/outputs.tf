output "scim_bridge_url" {
  description = "The URL of your 1Password SCIM Bridge"
  value       = "https://${var.domain_name}"
}

output "cloudwatch_log_group" {
  description = "Where you can find your SCIM bridge logs"
  value       = aws_cloudwatch_log_group.op_scim_bridge.name
}

output "loadbalancer_dns_name" {
  description = "The name of the load balancer to target in your DNS"
  value       = var.using_route53 ? null : aws_alb.op_scim_bridge.dns_name
}
