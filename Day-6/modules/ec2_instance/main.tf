provider "aws" {
  region = "us-east-1"
}

variable "ami" {
  description = "AMI image id for ec2 instance"
}

variable "instance_type" {
  description = "Type of instance flavor, eg: t2.micro"
}

resource "aws_instance" "example" {
  ami = var.ami
  instance_type = var.instance_type
}
