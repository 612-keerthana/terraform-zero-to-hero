terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc1" {
  source = "terraform-aws-modules/vpc/aws"

  name = "flipkart-vpc-dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# Security Group Web
resource "aws_security_group" "Web_SG1" {
  name        = "Flipkart_Web_SG1"
  description = "Allow TCP inbound traffic and all outbound traffic"
  vpc_id      = module.vpc1.vpc_id

  tags = {
    Name = "Flipkart_Web_SG1"
    Managed_by = "terraform"
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

# EC2 Instance Web1 - Pub Sub
resource "aws_instance" "Web1" {
  ami = "ami-004f790b835b26145"
  instance_type = "t3.micro"
  key_name = "aws_devops"
  subnet_id = module.vpc1.public_subnets[0] # Terraform and AWS automatically figure out which VPC your EC2 instance with subnet
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.Web_SG1.id]

  tags = {
    Name = "flipkart-web1"
    Managed_by = "terraform"
  }
}

# Output Web Public IP Address
output "web1_public_ip" {
  value = aws_instance.Web1.public_ip
}
output "web1_private_ip" {
  value = aws_instance.Web1.private_ip
}

module "vpc2" {
  source = "terraform-aws-modules/vpc/aws"

  name = "flipkart-vpc-prod"
  cidr = "10.1.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  tags = {
    Terraform = "true"
    Environment = "prod"
  }
}

