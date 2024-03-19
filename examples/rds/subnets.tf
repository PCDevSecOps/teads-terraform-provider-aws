resource "aws_subnet" "subnet_1" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.subnet_1_cidr}"
  availability_zone = "${var.az_1}"

  tags = {
    Name      = "main_subnet1"
    yor_trace = "ce5d6d4d-45ca-456b-a7d5-9e318ccb4a7c"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.subnet_2_cidr}"
  availability_zone = "${var.az_2}"

  tags = {
    Name      = "main_subnet2"
    yor_trace = "bc35cade-a340-4df2-8a40-a51bd69d08d1"
  }
}
