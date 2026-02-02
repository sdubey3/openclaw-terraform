output "trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "trail_name" {
  description = "Name of the CloudTrail trail"
  value       = aws_cloudtrail.main.name
}

output "s3_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for CloudTrail (if enabled)"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}
