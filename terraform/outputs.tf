output "server_public_id" {
  value = aws_instance.app_server.public_ip
  description = "Public IP address of the EC2 instance"
}

output "vpc_id" {
  value = aws_vpc.main.id
  description = "ID of the VPC"
}