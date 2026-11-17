output "vpc_id" {
  description = "ID of the project VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs, keyed by availability zone suffix (a, b)."
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}
