/*
  Elastic IPs for VPC NAT Gateway.
*/
resource "aws_eip" "ngw_ip" {
  count = "${length(var.subnet_cidr["private"])}"
  vpc   = true

  tags {
    Name        = "${var.env}-${var.application}-eip${count.index}"
    Application = "${var.application}"
    env         = "${var.env}"
    type        = "${var.type}"
  }
}

/*
  VPC NAT Gateway is used to allow EC2 instances in private subnets to connect to the Internet.
*/
resource "aws_nat_gateway" "ngw" {
  count         = "${length(var.subnet_cidr["private"])}"
  allocation_id = "${element(aws_eip.ngw_ip.*.id,count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id,count.index)}"

  tags {
    Application = "${var.application}"
    env         = "${var.env}"
    type        = "${var.type}"
    Name        = "${var.env}-${var.application}-ngw"
  }
}

/*
  Add default route through NAT gateway for private subnets
*/
resource "aws_route_table" "private" {
  count  = "${length(var.subnet_cidr["private"])}"
  vpc_id = "${aws_vpc.infra.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.ngw.*.id,count.index)}"
  }

  tags {
    Application = "${var.application}"
    env         = "${var.env}"
    type        = "${var.type}"
    Name        = "${var.env}-${var.application}-private-route-table${count.index}"
  }
}

/*
  Associate NAT Gateway with private subnets.
*/
resource "aws_route_table_association" "private" {
  count          = "${length(var.subnet_cidr["private"])}"
  subnet_id      = "${element(aws_subnet.private.*.id,count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id,count.index)}"
}
