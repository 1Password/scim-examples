output "vpc" {
  value = "${aws_vpc.infra.id}"
}

output "infra_private_subnets" {
  value = "${aws_subnet.private.*.id}"
}

output "infra_public_subnets" {
  value = "${aws_subnet.public.*.id}"
}
