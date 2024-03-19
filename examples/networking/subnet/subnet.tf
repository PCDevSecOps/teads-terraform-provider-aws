resource "aws_subnet" "main" {
  cidr_block        = "${cidrsubnet(data.aws_vpc.target.cidr_block, 2, lookup(var.az_numbers, data.aws_availability_zone.target.name_suffix))}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${var.availability_zone}"
  tags = {
    yor_trace = "17004ccc-46e8-4022-879d-2883ab724bdf"
  }
}

resource "aws_route_table" "main" {
  vpc_id = "${var.vpc_id}"
  tags = {
    yor_trace = "42e47ab2-e7e8-471a-a883-9056ee36ad1e"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.main.id}"
}
