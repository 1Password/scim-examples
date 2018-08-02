/*
  Public subnets. For NAT Gateway and load balancer.
*/
resource "aws_subnet" "public" {
  count             = "${length(var.subnet_cidr["public"])}"
  vpc_id            = "${aws_vpc.infra.id}"
  cidr_block        = "${element(var.subnet_cidr["public"],count.index)}"
  availability_zone = "${var.az[count.index]}"

  tags {
    Application = "${var.application}"
    env         = "${var.env}"
    type        = "${var.type}"
    Name        = "${var.env}-${var.application}-public-subnet-${count.index}"
  }
}

/*
  Instance private subnets.
*/
resource "aws_subnet" "private" {
  count             = "${length(var.subnet_cidr["private"])}"
  vpc_id            = "${aws_vpc.infra.id}"
  cidr_block        = "${element(var.subnet_cidr["private"],count.index)}"
  availability_zone = "${var.az[count.index]}"

  tags {
    Application = "${var.application}"
    env         = "${var.env}"
    type        = "${var.type}"
    Name        = "${var.env}-${var.application}-private-subnet-${count.index}"
  }
}

/*
  VPC routing table.
*/
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.infra.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Application = "${var.application}"
    env         = "${var.env}"
    type        = "${var.type}"
    Name        = "${var.env}-${var.application}-public-route-table"
  }
}

/*
  Associate routing table with the public subnets.
*/
resource "aws_route_table_association" "public" {
  count          = "${length(var.subnet_cidr["public"])}"
  subnet_id      = "${element(aws_subnet.public.*.id,count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}
