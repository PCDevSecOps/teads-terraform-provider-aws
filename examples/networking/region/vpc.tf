resource "aws_vpc" "main" {
  cidr_block = "${cidrsubnet(var.base_cidr_block, 4, lookup(var.region_numbers, var.region))}"
  tags = {
    yor_trace = "83278b70-ef7c-4696-8175-80080cff23d8"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    yor_trace = "3ec9eca4-c9ae-488a-a306-cb80c87028a9"
  }
}
