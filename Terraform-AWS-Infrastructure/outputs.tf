
output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.my_ec2.id
}

output "public_ip" {
  description = "EC2 Public IP"
  value       = aws_instance.my_ec2.public_ip
}

output "public_dns" {
  description = "EC2 Public DNS"
  value       = aws_instance.my_ec2.public_dns
}
