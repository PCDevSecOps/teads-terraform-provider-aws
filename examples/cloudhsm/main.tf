provider "aws" {
  region = "${var.aws_region}"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "cloudhsm_v2_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name      = "example-aws_cloudhsm_v2_cluster"
    yor_trace = "ece31089-c9cc-4a42-8674-1e8e0eda13a8"
  }
}

resource "aws_subnet" "cloudhsm_v2_subnets" {
  count                   = 2
  vpc_id                  = "${aws_vpc.cloudhsm_v2_vpc.id}"
  cidr_block              = "${element(var.subnets, count.index)}"
  map_public_ip_on_launch = false
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags = {
    Name      = "example-aws_cloudhsm_v2_cluster"
    yor_trace = "8e6e0405-5b3a-4b10-8511-e6d83b74ecdd"
  }
}

resource "aws_cloudhsm_v2_cluster" "cloudhsm_v2_cluster" {
  hsm_type   = "hsm1.medium"
  subnet_ids = ["${aws_subnet.cloudhsm_v2_subnets.*.id}"]

  tags = {
    Name      = "example-aws_cloudhsm_v2_cluster"
    yor_trace = "4155567a-7b38-463c-8fa0-c2d20a20c5aa"
  }
}

resource "aws_cloudhsm_v2_hsm" "cloudhsm_v2_hsm" {
  subnet_id  = "${aws_subnet.cloudhsm_v2_subnets.0.id}"
  cluster_id = "${aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.cluster_id}"
}

data "aws_cloudhsm_v2_cluster" "cluster" {
  cluster_id = "${aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.cluster_id}"
  depends_on = ["aws_cloudhsm_v2_hsm.cloudhsm_v2_hsm"]
}
