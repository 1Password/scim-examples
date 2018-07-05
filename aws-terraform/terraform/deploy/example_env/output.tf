output "env" {
  value = "${var.env}"
}

output "type" {
  value = "${var.type}"
}

output "op-scim_bridge_endpoint_url" {
  value = "https://${module.scim-app.app_lb_dns_name}"
}
