output "server_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "Public IP address of the EC2 instance"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the VPC"
}
output "ecr_repository_url" {
  value = aws_ecr_repository.shipyard_app.repository_url
}

output "instance_id" {
  value       = aws_instance.app_server.id
  description = "ID of the EC2 instance"
}