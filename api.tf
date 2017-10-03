# API layer.

# configuration parameters

variable "api_service_port" {
  type = "string"
  default = "80"
}

variable "ssh_source" {
  type = "string"
  default = "0.0.0.0/0" # not in a real setup!
}

variable "api_instance_type" {
  type = "string"
  default = "m4.large"
}

variable "api_ami_id" {
  type = "string"
  default = "ami-10547475" # Ubuntu 16.04 LTS, us-east-2
}

variable "api_key_pair_name" {
  type = "string"
  default = "interview"
}

# security config

resource "aws_security_group" "api_elb" {
  vpc_id = "${aws_vpc.interview.id}"
  ingress {
    protocol = "tcp"
    from_port = "80"
    to_port = "80"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "API ELB"
    Description = "Inbound security group for API load balancer"
  }
}

resource "aws_security_group" "api_instance" {
  vpc_id = "${aws_vpc.interview.id}"
  # SSH access
  ingress {
    protocol = "tcp"
    from_port = "22"
    to_port = "22"
    cidr_blocks = ["${var.ssh_source}"]
  }
  # API access from load balancer
  ingress {
    protocol = "tcp"
    from_port = "${var.api_service_port}"
    to_port = "${var.api_service_port}"
    security_groups = ["${aws_security_group.api_elb.id}"]
  }
  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "API Instances"
    Description = "Inbound security group for API instances"
  }
}

resource "aws_elb" "api" {
  health_check {
    healthy_threshold = "3"
    unhealthy_threshold = "2"
    timeout = "3"
    target = "HTTP:${var.api_service_port}/"
    interval = "30"
  }

  listener {
    instance_port = "${var.api_service_port}"
    instance_protocol = "http"
    lb_port = "80"
    lb_protocol = "http"
  }

  security_groups = ["${aws_security_group.api_elb.id}"]
  subnets = [
    "${aws_subnet.public_2a.id}",
    "${aws_subnet.public_2b.id}",
    "${aws_subnet.public_2c.id}"
  ]
}

# access policy

data "aws_iam_policy_document" "write_cloudwatch_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "write_cloudwatch_logs" {
  policy = "${data.aws_iam_policy_document.write_cloudwatch_logs.json}"
}

data "aws_iam_policy_document" "instance_profile_assume" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_instance" {
  assume_role_policy = "${data.aws_iam_policy_document.instance_profile_assume.json}"
}

resource "aws_iam_role_policy_attachment" "api_instance_write_cloudwatch_logs" {
  role = "${aws_iam_role.api_instance.name}"
  policy_arn = "${aws_iam_policy.write_cloudwatch_logs.arn}"
}

resource "aws_iam_instance_profile" "api" {
  role = "${aws_iam_role.api_instance.name}"
}

# API host (just a blank nginx)

resource "aws_instance" "api" {
  # ssh key-pair "Interview" is already provisioned in the EC2 account and needs to be
  # added to ssh-agent
  connection {
    user = "ubuntu"
  }
  instance_type = "${var.api_instance_type}"
  ami = "${var.api_ami_id}"
  key_name = "${var.api_key_pair_name}"
  vpc_security_group_ids = [
    "${aws_security_group.api_instance.id}",
    "${aws_security_group.api_db_accessor.id}"
  ]
  subnet_id = "${aws_subnet.public_2a.id}"

  # Install a fake API service, just a blank nginx
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start"
    ]
  }
}

resource "aws_elb_attachment" "api" {
  elb = "${aws_elb.api.id}"
  instance = "${aws_instance.api.id}"
}
