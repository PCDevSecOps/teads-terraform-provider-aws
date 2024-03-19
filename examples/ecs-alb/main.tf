# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

## EC2

### Network

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
  tags = {
    yor_trace = "5c95d3ce-076c-48b1-998f-b86f72751b3d"
  }
}

resource "aws_subnet" "main" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"
  tags = {
    yor_trace = "6fb94e67-580b-4249-9828-f078e3598447"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    yor_trace = "1fc9d0c6-fcee-48ad-b0ec-216fa47bff00"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    yor_trace = "1d03c365-6014-462a-88b3-ab773dc1e018"
  }
}

resource "aws_route_table_association" "a" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.main.*.id, count.index)}"
  route_table_id = "${aws_route_table.r.id}"
}

### Compute

resource "aws_autoscaling_group" "app" {
  name                 = "tf-test-asg"
  vpc_zone_identifier  = ["${aws_subnet.main.*.id}"]
  min_size             = "${var.asg_min}"
  max_size             = "${var.asg_max}"
  desired_capacity     = "${var.asg_desired}"
  launch_configuration = "${aws_launch_configuration.app.name}"
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml")}"

  vars = {
    aws_region         = "${var.aws_region}"
    ecs_cluster_name   = "${aws_ecs_cluster.main.name}"
    ecs_log_level      = "info"
    ecs_agent_version  = "latest"
    ecs_log_group_name = "${aws_cloudwatch_log_group.ecs.name}"
  }
}

data "aws_ami" "stable_coreos" {
  most_recent = true

  filter {
    name   = "description"
    values = ["CoreOS Container Linux stable *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["595879546273"] # CoreOS
}

resource "aws_launch_configuration" "app" {
  security_groups = [
    "${aws_security_group.instance_sg.id}",
  ]

  key_name                    = "${var.key_name}"
  image_id                    = "${data.aws_ami.stable_coreos.id}"
  instance_type               = "${var.instance_type}"
  iam_instance_profile        = "${aws_iam_instance_profile.app.name}"
  user_data                   = "${data.template_file.cloud_config.rendered}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

### Security

resource "aws_security_group" "lb_sg" {
  description = "controls access to the application ELB"

  vpc_id = "${aws_vpc.main.id}"
  name   = "tf-ecs-lbsg"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  tags = {
    yor_trace = "f1b4185c-c9c6-43f8-a585-9dd080049f98"
  }
}

resource "aws_security_group" "instance_sg" {
  description = "controls direct access to application instances"
  vpc_id      = "${aws_vpc.main.id}"
  name        = "tf-ecs-instsg"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = [
      "${var.admin_cidr_ingress}",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 32768
    to_port   = 61000

    security_groups = [
      "${aws_security_group.lb_sg.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    yor_trace = "ab8dc61e-4dd7-4b4f-a58d-a76f9d835dcc"
  }
}

## ECS

resource "aws_ecs_cluster" "main" {
  name = "terraform_example_ecs_cluster"
  tags = {
    yor_trace = "ea723cbb-ce1f-4d9f-a01e-7f2ca77fbc8a"
  }
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/task-definition.json")}"

  vars = {
    image_url        = "ghost:latest"
    container_name   = "ghost"
    log_group_region = "${var.aws_region}"
    log_group_name   = "${aws_cloudwatch_log_group.app.name}"
  }
}

resource "aws_ecs_task_definition" "ghost" {
  family                = "tf_example_ghost_td"
  container_definitions = "${data.template_file.task_definition.rendered}"
  tags = {
    yor_trace = "58936022-4401-4a44-b68b-beae157f9582"
  }
}

resource "aws_ecs_service" "test" {
  name            = "tf-example-ecs-ghost"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.ghost.arn}"
  desired_count   = "${var.service_desired}"
  iam_role        = "${aws_iam_role.ecs_service.name}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.test.id}"
    container_name   = "ghost"
    container_port   = "2368"
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_alb_listener.front_end",
  ]
  tags = {
    yor_trace = "f4174c52-91f2-4cfa-b7b7-3a78d4efd17d"
  }
}

## IAM

resource "aws_iam_role" "ecs_service" {
  name = "tf_example_ecs_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    yor_trace = "71ca2212-e619-41cc-b5fe-a1bf48ca8ac4"
  }
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "tf_example_ecs_policy"
  role = "${aws_iam_role.ecs_service.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "app" {
  name = "tf-ecs-instprofile"
  role = "${aws_iam_role.app_instance.name}"
  tags = {
    yor_trace = "2690c821-2bd7-41af-96dc-409c13158570"
  }
}

resource "aws_iam_role" "app_instance" {
  name = "tf-ecs-example-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    yor_trace = "91c63be2-bbbb-47c2-919d-bf230fcea7d4"
  }
}

data "template_file" "instance_profile" {
  template = "${file("${path.module}/instance-profile-policy.json")}"

  vars = {
    app_log_group_arn = "${aws_cloudwatch_log_group.app.arn}"
    ecs_log_group_arn = "${aws_cloudwatch_log_group.ecs.arn}"
  }
}

resource "aws_iam_role_policy" "instance" {
  name   = "TfEcsExampleInstanceRole"
  role   = "${aws_iam_role.app_instance.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}

## ALB

resource "aws_alb_target_group" "test" {
  name     = "tf-example-ecs-ghost"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
  tags = {
    yor_trace = "ead0777e-e25b-4dac-8dfc-74121ef9c1a2"
  }
}

resource "aws_alb" "main" {
  name            = "tf-example-alb-ecs"
  subnets         = ["${aws_subnet.main.*.id}"]
  security_groups = ["${aws_security_group.lb_sg.id}"]
  tags = {
    yor_trace = "fb421596-d6ff-4a9e-9537-06dc2e94ad6f"
  }
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.test.id}"
    type             = "forward"
  }
  tags = {
    yor_trace = "dcb099fe-b63d-404a-a9d5-17b572863d7e"
  }
}

## CloudWatch Logs

resource "aws_cloudwatch_log_group" "ecs" {
  name = "tf-ecs-group/ecs-agent"
  tags = {
    yor_trace = "d0549237-140b-4aa4-b992-f0d438a5612f"
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name = "tf-ecs-group/app-ghost"
  tags = {
    yor_trace = "dceb9ef8-0078-4c86-b849-bacddf6ee026"
  }
}
