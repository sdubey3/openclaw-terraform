output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.openclaw.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.openclaw.arn
}
