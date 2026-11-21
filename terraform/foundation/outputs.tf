output "vpc_id" {
  description = "ID of the project VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs, keyed by availability zone suffix (a, b)."
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "ci_instance_id" {
  description = "CI machine instance ID, used to start and stop it and for Session Manager"
  value       = aws_instance.ci.id
}

output "ci_security_group_id" {
  description = "CI machine security group ID"
  value       = aws_security_group.ci.id
}

output "ci_public_ip" {
  description = "Elastic IP of the CI machine"
  value       = aws_eip.ci.public_ip
}

output "ansible_bucket_name" {
  description = "S3 bucket for Ansible's Session Manager file transfers"
  value       = aws_s3_bucket.ansible.bucket
}
