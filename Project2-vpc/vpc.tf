#Provider AWS 
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-${var.client_name}"
    Managed_by = var.managed_by
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-${var.client_name}"
    Managed_by = var.managed_by
  }
}

# Public Sub 1
resource "aws_subnet" "pub_sub1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  # map_public_ip_on_launch = true 
  # Any EC2 instance launched inside this subnet will automatically receive a public IP address by default

  tags = {
    Name = "pub_sub1_${var.client_name}"
    Managed_by = var.managed_by
  }
}

# Private Sub 1
resource "aws_subnet" "priv_sub1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "priv_sub1_${var.client_name}"
    Managed_by = var.managed_by
  }
}

# Pub RT1
resource "aws_route_table" "pub_RT1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "pub_RT1_${var.client_name}"
    Managed_by = var.managed_by

  }
}

# Priv RT1
resource "aws_route_table" "priv_RT1" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "priv_RT1_${var.client_name}"
    Managed_by = var.managed_by
  }
}

# Pub Sub1 Association
resource "aws_route_table_association" "pub_RTA1" {
  subnet_id      = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.pub_RT1.id
}

# Private Sub1 Association
resource "aws_route_table_association" "priv_RTA1" {
  subnet_id      = aws_subnet.priv_sub1.id
  route_table_id = aws_route_table.priv_RT1.id
}

# Security Group Web
resource "aws_security_group" "Web_SG1" {
  name        = "Web_SG1_${var.client_name}"
  description = "Allow TCP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "Web_SG1_${var.client_name}"
    Managed_by = var.managed_by
  }
}

resource "aws_vpc_security_group_ingress_rule" "Web_SG1_ingress_ip" {
  security_group_id = aws_security_group.Web_SG1.id
  cidr_ipv4         = "124.123.80.27/32"
  from_port         = 0
  ip_protocol       = "-1"
  to_port           = 0
}

resource "aws_vpc_security_group_ingress_rule" "Web_SG1_ingress_all" {
  security_group_id = aws_security_group.Web_SG1.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "Web_SG1_egress" {
  security_group_id = aws_security_group.Web_SG1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Security Group DB
resource "aws_security_group" "DB_SG1" {
  name        = "DB_SG1_${var.client_name}"
  description = "Allow TCP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "DB_SG1_${var.client_name}"
    Managed_by = var.managed_by
  }
}

resource "aws_vpc_security_group_ingress_rule" "DB_SG1_ingress_all" {
  security_group_id = aws_security_group.DB_SG1.id
  referenced_security_group_id = aws_security_group.Web_SG1.id # Security Group Chaining
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_vpc_security_group_egress_rule" "DB_SG1_egress" {
  security_group_id = aws_security_group.DB_SG1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# EC2 Instance Web1 - Pub Sub
resource "aws_instance" "Web1" {
  ami = var.ami_id
  instance_type = var.instance_type
  key_name = "aws_devops"
  subnet_id = aws_subnet.pub_sub1.id # Terraform and AWS automatically figure out which VPC your EC2 instance with subnet
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.Web_SG1.id]

  tags = {
    Name = "web1-${var.client_name}"
    Managed_by = var.managed_by
  }
}

# Ec2 Instance DB1 - Private Sub
resource "aws_instance" "DB1" {
  ami = var.ami_id
  instance_type = var.instance_type
  key_name = "aws_devops"
  subnet_id = aws_subnet.priv_sub1.id # Terraform and AWS automatically figure out which VPC your EC2 instance with subnet
  vpc_security_group_ids = [aws_security_group.DB_SG1.id]

  tags = {
    Name = "DB1-${var.client_name}"
    Managed_by = var.managed_by
  }
}

# Output Web Public IP Address
output "web1_public_ip" {
  value = aws_instance.Web1.public_ip
}
output "web1_private_ip" {
  value = aws_instance.Web1.private_ip
}

# Output DB Private IP Address
output "DB1_private_ip" {
  value = aws_instance.DB1.private_ip
}
