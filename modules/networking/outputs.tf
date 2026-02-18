output "ec2_security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.openclaw.id
}

output "efs_security_group_id" {
  description = "Security group ID for EFS mount targets"
  value       = aws_security_group.efs.id
}

output "flow_log_group_name" {
  description = "CloudWatch log group name for VPC Flow Logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
