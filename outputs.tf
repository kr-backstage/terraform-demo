output "application_url" {
  description = "HTTP endpoint of the demo web application"
  value       = "http://${aws_eip.web.public_ip}"
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.web.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "Security group applied to the EC2 instance"
  value       = aws_security_group.web.id
}

output "vpc_id" {
  description = "ID of the VPC that hosts the demo environment"
  value       = aws_vpc.main.id
}
