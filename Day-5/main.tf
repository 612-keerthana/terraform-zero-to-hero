# Define the AWS provider configuration.
provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region.
}

# Variables
variable "cidr" {
  default = "10.0.0.0/16"
}

# Keypair deploy on to aws
resource "aws_key_pair" "flask_app_key" {
  key_name   = "flask_app_key"  # Replace with your desired key name
  public_key = file("~/.ssh/id_rsa.pub") # Replace with the path to your public key file
}

# VPC
resource "aws_vpc" "flask_app_vpc" {
  cidr_block = var.cidr
  tags = {
    Name = "flask_app_vpc"
  }
}

# Public subnet
resource "aws_subnet" "flask_app_pub_sub1" {
  vpc_id                  = aws_vpc.flask_app_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "flask_app_pub_sub1"
  }
}

# Internet gateway 
resource "aws_internet_gateway" "flask_app_igw" {
  vpc_id = aws_vpc.flask_app_vpc.id
  tags = {
    Name = "flask_app_igw"
  }
}

# Route table for public subnet
resource "aws_route_table" "flask_app_pub_RT" {
  vpc_id = aws_vpc.flask_app_vpc.id
  route {
    # Directs all outbound traffic to the Internet Gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.flask_app_igw.id
  }
  tags = {
    Name = "flask_app_pub_RT"
  }
}

# Associate the Route Table with the public subnet
resource "aws_route_table_association" "flask_app_pub_RTA1" {
  subnet_id      = aws_subnet.flask_app_pub_sub1.id
  route_table_id = aws_route_table.flask_app_pub_RT.id
}

# Security Group to allow SSH (port 22) and web traffic (port 80)
resource "aws_security_group" "flask_app_web_sg" {
  name        = "flask_app_web_sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.flask_app_vpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flask_app_web_sg"
  }
}

# EC2 instance in the public subnet

resource "aws_instance" "flask_app_web_server" {
  ami           = "ami-0b6c6ebed2801a5cb"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.flask_app_key.key_name
  subnet_id     = aws_subnet.flask_app_pub_sub1.id
  vpc_security_group_ids = [aws_security_group.flask_app_web_sg.id]
  # Because map_public_ip_on_launch is true on the subnet, this instance gets a public IP
  
  tags = {
    Name = "flask_app_web_server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"  # Replace with the appropriate username for your EC2 instance
    private_key = file("~/.ssh/id_rsa")  # Replace with the path to your private key
    host        = self.public_ip
  }

  # File provisioner to copy a file from local to the remote EC2 instance
  provisioner "file" {
    source      = "app.py"  # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/ubuntu",
      "sudo apt install -y python3-flask",
      "sudo nohup python3 app.py &"
    ]
  }
}
