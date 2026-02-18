output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.openclaw_data.id
}

output "efs_dns_name" {
  description = "EFS file system DNS name"
  value       = aws_efs_file_system.openclaw_data.dns_name
}
