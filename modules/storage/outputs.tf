output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.openclaw_data.id
}

output "efs_dns_name" {
  description = "EFS file system DNS name"
  value       = aws_efs_file_system.openclaw_data.dns_name
}

output "s3_bucket_name" {
  description = "S3 bucket name for backups"
  value       = aws_s3_bucket.openclaw_backups.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for backups"
  value       = aws_s3_bucket.openclaw_backups.arn
}
