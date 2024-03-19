# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_elb" "web" {
  name = "terraform-example-elb"

  # The same availability zone as our instances
  availability_zones = ["${aws_instance.web.*.availability_zone}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  # The instances are registered automatically
  instances = ["${aws_instance.web.*.id}"]
  tags = {
    yor_trace = "38f0a3ca-206b-426c-a442-b9ad1ca3016d"
  }
}

resource "aws_instance" "web" {
  instance_type = "m1.small"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"

  # This will create 4 instances
  count = 4
  tags = {
    yor_trace = "8acbeb52-b73b-474d-b3e9-d23d06d12138"
  }
}
