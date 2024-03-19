provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_cloudwatch_event_rule" "foo" {
  name = "${var.rule_name}"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "autoscaling.amazonaws.com"
    ]
  }
}
PATTERN

  role_arn = "${aws_iam_role.role.arn}"
  tags = {
    yor_trace = "6f1550ae-c33e-4d18-8b17-0253c1bbff52"
  }
}

resource "aws_iam_role" "role" {
  name = "${var.iam_role_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
  tags = {
    yor_trace = "33ff3cdc-70b7-47ad-be46-c0f044264cf7"
  }
}

resource "aws_iam_role_policy" "policy" {
  name = "tf-example-policy"
  role = "${aws_iam_role.role.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kinesis:PutRecord",
        "kinesis:PutRecords"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_cloudwatch_event_target" "foobar" {
  rule      = "${aws_cloudwatch_event_rule.foo.name}"
  target_id = "${var.target_name}"
  arn       = "${aws_kinesis_stream.foo.arn}"
}

resource "aws_kinesis_stream" "foo" {
  name        = "${var.stream_name}"
  shard_count = 1
  tags = {
    yor_trace = "5eb29408-3415-469b-bcc9-6834ab860895"
  }
}
