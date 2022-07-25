resource "aws_vpc" "vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true # Needed to mount e.g. NFS
  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_subnet" "primary" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "eu-west-1a"
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Primary"
  }
}

resource "aws_subnet" "secondary" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "eu-west-1b"
  cidr_block        = "10.10.1.0/24"
  tags = {
    Name = "Secondary"
  }
}

resource "aws_security_group" "ssh-allowed" {
  name        = "standard_ssh"
  description = "Allows ssh inbound traffic via standard port"
  vpc_id      = aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.primary.id
  route_table_id = aws_route_table.rt.id
}