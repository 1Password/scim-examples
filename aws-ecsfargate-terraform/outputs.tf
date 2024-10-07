output "scim_bridge_cname" {
  description = "Create this CNAME record in your DNS provider to point to the load balancer."
  value = var.using_route53 ? null : {
    name  = "${var.domain_name}."
    value = "${module.network.lb_dns_name}."
  }
}

output "scim_bridge_url" {
  description = "The URL of your 1Password SCIM Bridge to use with your identity provider."
  value       = "https://${var.domain_name}"
}
