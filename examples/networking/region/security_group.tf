resource "aws_security_group" "region" {
  name        = "region"
  description = "Open access within this region"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }
  tags = {
    yor_trace = "73b2fcb8-acfe-4e73-be52-393a1ededa47"
  }
}

resource "aws_security_group" "internal-all" {
  name        = "internal-all"
  description = "Open access within the full internal network"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.base_cidr_block}"]
  }
  tags = {
    yor_trace = "d34eee36-94b8-4fa6-8b2c-4e9046db2860"
  }
}
