variable "ami_id" {
  description = "EC2 Instance Ubuntu Image ID"
  type = string
  default = "ami-0b6d9d3d33ba97d99"
}

variable "instance_type" {
  description = "EC2 Instance flavor"
  type = string
  default = "t2.micro"
}

variable "client_name" {
  description = "Client Name of this project"
  type = string
  default = "example"
}

variable "managed_by" {
  description = "Resource managed by"
  type = string
  default = "devops"
}
