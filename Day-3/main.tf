provider "aws" {
  region = "us-east-1"
}

variable "ami" {
  description = "EC2 instance AMI Image"
}

variable "instance_type" {
  description = "EC2 Instance type/flavor"
}

variable "key_name" {
  description = "EC2 Instance key pair to connect"
}

module "ec2_instance" {
  source = "./modules/ec2_instance"
  ami_value = var.ami
  instance_type_value = var.instance_type
  key_name_value = var.key_name
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value = module.ec2_instance.public_ip_address
}
