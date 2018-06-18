resource "aws_route53_zone" "internal-zone" {
  name    = "${var.application}-${var.env}.int"
  vpc_id  = "${aws_vpc.infra.id}"
  comment = "Internal DNS for ${var.application}-${var.env} VPC"

  tags {
    Application = "${var.application}"
    Name        = "${var.env}-${var.application}-internal-dns"
    env         = "${var.env}"
    type        = "${var.type}"
  }
}
