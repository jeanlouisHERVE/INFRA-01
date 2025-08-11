output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.custom.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}