provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2_instance" {
  ami = "ami-0f3caa1cf4417e51b"
  instance_type = "t2.micro"
  key_name = "aws_devops"
}

output "ec2_public_ip_address" {
  value = aws_instance.ec2_instance.public_ip
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "xyz-tf-project-store" # change this
}

#No longer required
''' resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
} '''
