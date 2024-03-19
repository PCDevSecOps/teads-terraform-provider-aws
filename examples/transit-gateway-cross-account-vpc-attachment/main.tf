// First account owns the transit gateway and accepts the VPC attachment.
provider "aws" {
  alias = "first"

  region     = "${var.aws_region}"
  access_key = "${var.aws_first_access_key}"
  secret_key = "${var.aws_first_secret_key}"
}

// Second account owns the VPC and creates the VPC attachment.
provider "aws" {
  alias = "second"

  region     = "${var.aws_region}"
  access_key = "${var.aws_second_access_key}"
  secret_key = "${var.aws_second_secret_key}"
}

data "aws_availability_zones" "available" {
  provider = "aws.second"

  state = "available"
}

data "aws_caller_identity" "second" {
  provider = "aws.second"
}

resource "aws_ec2_transit_gateway" "example" {
  provider = "aws.first"

  tags = {
    Name      = "terraform-example"
    yor_trace = "effd761b-26c8-4e91-9cf4-bb26f2541fe8"
  }
}

resource "aws_ram_resource_share" "example" {
  provider = "aws.first"

  name = "terraform-example"

  tags = {
    Name      = "terraform-example"
    yor_trace = "953f2836-6a2e-446a-b719-c92398f3febc"
  }
}

// Share the transit gateway...
resource "aws_ram_resource_association" "example" {
  provider = "aws.first"

  resource_arn       = "${aws_ec2_transit_gateway.example.arn}"
  resource_share_arn = "${aws_ram_resource_share.example.id}"
}

// ...with the second account.
resource "aws_ram_principal_association" "example" {
  provider = "aws.first"

  principal          = "${data.aws_caller_identity.second.account_id}"
  resource_share_arn = "${aws_ram_resource_share.example.id}"
}

resource "aws_vpc" "example" {
  provider = "aws.second"

  cidr_block = "10.0.0.0/16"

  tags = {
    Name      = "terraform-example"
    yor_trace = "0edffef3-0c61-4411-bab5-f7c8ea0befe2"
  }
}

resource "aws_subnet" "example" {
  provider = "aws.second"

  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block        = "10.0.0.0/24"
  vpc_id            = "${aws_vpc.example.id}"

  tags = {
    Name      = "terraform-example"
    yor_trace = "350a9ab2-f996-4e45-b34b-7b56ed8a6cdc"
  }
}

// Create the VPC attachment in the second account...
resource "aws_ec2_transit_gateway_vpc_attachment" "example" {
  provider = "aws.second"

  depends_on = ["aws_ram_principal_association.example", "aws_ram_resource_association.example"]

  subnet_ids         = ["${aws_subnet.example.id}"]
  transit_gateway_id = "${aws_ec2_transit_gateway.example.id}"
  vpc_id             = "${aws_vpc.example.id}"

  tags = {
    Name      = "terraform-example"
    Side      = "Creator"
    yor_trace = "1865115c-a229-4983-8f95-faf65a17131b"
  }
}

// ...and accept it in the first account.
resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "example" {
  provider = "aws.first"

  transit_gateway_attachment_id = "${aws_ec2_transit_gateway_vpc_attachment.example.id}"

  tags = {
    Name      = "terraform-example"
    Side      = "Accepter"
    yor_trace = "60351ed4-c9e0-4a93-8072-7d76fe4e9fb6"
  }
}
