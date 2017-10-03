# VPC

resource "aws_vpc" "interview" {
  cidr_block = "172.20.0.0/16"
  enable_dns_hostnames = "true"
  tags {
    Name = "interview-vpc"
  }
}

# Subnets (private and public in each AZ)

resource "aws_subnet" "private_2a" {
  vpc_id = "${aws_vpc.interview.id}"
  availability_zone = "us-east-2a"
  cidr_block = "172.20.0.0/20"
  tags {
    Name = "interview-subnet-private-2a"
  }
}

resource "aws_subnet" "public_2a" {
  vpc_id = "${aws_vpc.interview.id}"
  availability_zone = "us-east-2a"
  cidr_block = "172.20.16.0/20"
  map_public_ip_on_launch = "true"
  tags {
    Name = "interview-subnet-public-2a"
  }
}

resource "aws_subnet" "private_2b" {
  vpc_id = "${aws_vpc.interview.id}"
  availability_zone = "us-east-2b"
  cidr_block = "172.20.32.0/20"
  tags {
    Name = "interview-subnet-private-2b"
  }
}

resource "aws_subnet" "public_2b" {
  vpc_id = "${aws_vpc.interview.id}"
  availability_zone = "us-east-2b"
  cidr_block = "172.20.48.0/20"
  map_public_ip_on_launch = "true"
  tags {
    Name = "interview-subnet-public-2b"
  }
}

resource "aws_subnet" "private_2c" {
  vpc_id = "${aws_vpc.interview.id}"
  availability_zone = "us-east-2c"
  cidr_block = "172.20.64.0/20"
  tags {
    Name = "interview-subnet-private-2c"
  }
}

resource "aws_subnet" "public_2c" {
  vpc_id = "${aws_vpc.interview.id}"
  availability_zone = "us-east-2c"
  cidr_block = "172.20.80.0/20"
  map_public_ip_on_launch = "true"
  tags {
    Name = "interview-subnet-public-2c"
  }
}

# Public route table and gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.interview.id}"
  tags {
    Name = "interview-internet-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.interview.id}"
  tags {
    Name = "interview-routes-public"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw.id}"
}

# Private route tables and NAT gateways

resource "aws_eip" "nat_gateway_2a" {
}

resource "aws_eip" "nat_gateway_2b" {
}

resource "aws_eip" "nat_gateway_2c" {
}

resource "aws_nat_gateway" "nat_2a" {
  allocation_id = "${aws_eip.nat_gateway_2a.id}"
  subnet_id = "${aws_subnet.private_2a.id}"

  depends_on = ["aws_internet_gateway.igw"]
}

resource "aws_nat_gateway" "nat_2b" {
  allocation_id = "${aws_eip.nat_gateway_2b.id}"
  subnet_id = "${aws_subnet.private_2b.id}"

  depends_on = ["aws_internet_gateway.igw"]
}

resource "aws_nat_gateway" "nat_2c" {
  allocation_id = "${aws_eip.nat_gateway_2c.id}"
  subnet_id = "${aws_subnet.private_2c.id}"

  depends_on = ["aws_internet_gateway.igw"]
}

resource "aws_route_table" "private_2a" {
  vpc_id = "${aws_vpc.interview.id}"
  tags {
    Name = "interview-routes-private-2a"
  }
}

resource "aws_route_table" "private_2b" {
  vpc_id = "${aws_vpc.interview.id}"
  tags {
    Name = "interview-routes-private-2b"
  }
}

resource "aws_route_table" "private_2c" {
  vpc_id = "${aws_vpc.interview.id}"
  tags {
    Name = "interview-routes-private-2c"
  }
}

resource "aws_route" "private_nat_2a" {
  route_table_id = "${aws_route_table.private_2a.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat_2a.id}"
}

resource "aws_route" "private_nat_2b" {
  route_table_id = "${aws_route_table.private_2b.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat_2b.id}"
}

resource "aws_route" "private_nat_2c" {
  route_table_id = "${aws_route_table.private_2c.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat_2c.id}"
}

# Route table associations

resource "aws_route_table_association" "public_2a" {
  subnet_id = "${aws_subnet.public_2a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_2b" {
  subnet_id = "${aws_subnet.public_2b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_2c" {
  subnet_id = "${aws_subnet.public_2c.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private_2a" {
  subnet_id = "${aws_subnet.private_2a.id}"
  route_table_id = "${aws_route_table.private_2a.id}"
}

resource "aws_route_table_association" "private_2b" {
  subnet_id = "${aws_subnet.private_2b.id}"
  route_table_id = "${aws_route_table.private_2b.id}"
}

resource "aws_route_table_association" "private_2c" {
  subnet_id = "${aws_subnet.private_2c.id}"
  route_table_id = "${aws_route_table.private_2c.id}"
}

# Endpoints

resource "aws_vpc_endpoint" "s3" {
  vpc_id = "${aws_vpc.interview.id}"
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [
    "${aws_route_table.private_2a.id}",
    "${aws_route_table.private_2b.id}",
    "${aws_route_table.private_2c.id}"
  ]
}
