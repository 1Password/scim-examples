
output "app_lb_dns_name" {
  value = "${aws_route53_record.app_lb.fqdn}"
}
