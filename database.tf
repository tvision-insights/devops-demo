# API database.

# Configuration parameters

variable "db_az" {
  type = "string"
  default = "us-east-2b"
}
variable "db_instance_class" {
  type = "string"
  default = "db.m4.large"
}
variable "db_master_password" {
  type = "string"
}
variable "db_name" {
  type = "string"
  default = "api_db"
}
variable "db_size" {
  type = "string"
  default = "500"
}

# Access configuration

resource "aws_db_subnet_group" "api_db" {
  subnet_ids = [
    "${aws_subnet.private_2a.id}",
    "${aws_subnet.private_2b.id}",
    "${aws_subnet.private_2c.id}"
  ]
  tags {
    Name = "API DB subnet group"
  }
}

# This security group is a marker, anything wearing it is allowed in by the ingress rule
resource "aws_security_group" "api_db_accessor" {
  vpc_id = "${aws_vpc.interview.id}"
  tags {
    Name = "API database accessor marker"
    Description = "Attach this security group to an object to mark it allowed to access the API database"
  }
}

resource "aws_security_group" "api_db_access" {
  vpc_id = "${aws_vpc.interview.id}"
  tags {
    Name = "API database access"
    Description = "Allows inbound access to API database"
  }
}

resource "aws_security_group_rule" "api_db_from_accessor" {
  security_group_id = "${aws_security_group.api_db_access.id}"
  type = "ingress"
  protocol = "tcp"
  from_port = "${aws_db_instance.api_db.port}"
  to_port = "${aws_db_instance.api_db.port}"
  source_security_group_id = "${aws_security_group.api_db_accessor.id}"
}

resource "aws_security_group_rule" "api_db_egress" {
  security_group_id = "${aws_security_group.api_db_access.id}"
  type = "egress"
  protocol = "-1"
  from_port = "0"
  to_port = "0"
  cidr_blocks = ["0.0.0.0/0"]
}

# Database instance

resource "aws_db_instance" "api_db" {
  allocated_storage = "${var.db_size}"
  availability_zone = "${var.db_az}"
  backup_retention_period = "1"
  db_subnet_group_name = "${aws_db_subnet_group.api_db.id}"
  engine = "postgres"
  engine_version = "9.5.4"
  instance_class = "${var.db_instance_class}"
  password = "${var.db_master_password}"
  storage_encrypted = "true"
  storage_type = "gp2"
  username = "root"
  vpc_security_group_ids = ["${aws_security_group.api_db_access.id}"]
  tags {
    Name = "API DB"
  }
  skip_final_snapshot = true
}
