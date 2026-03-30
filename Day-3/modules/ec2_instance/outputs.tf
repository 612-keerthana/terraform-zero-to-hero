output "public_ip_address" {
  description = "Public IP address of EC2 instance"
  value = aws_instance.example.public_ip
}
