output "env" {
  value = "${var.env}"
}

output "type" {
  value = "${var.type}"
}

output "lb_pub_dns_name" {
  value = "${module.scim-app.app_lb_dns_name}"
}
