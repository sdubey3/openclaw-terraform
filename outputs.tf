output "instance_id" {
  description = "EC2 instance ID"
  value       = local.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the OpenClaw EC2 instance"
  value       = local.instance_public_ip
}

output "s3_bucket_name" {
  description = "S3 bucket name for backups"
  value       = aws_s3_bucket.openclaw_backups.id
}

output "ssm_connect_command" {
  description = "Connect via SSM Session Manager"
  value       = "aws ssm start-session --target ${local.instance_id} --region ${var.aws_region}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.openclaw.id
}

output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.openclaw_data.id
}

output "spot_request_id" {
  description = "Spot request ID (if using spot)"
  value       = var.use_spot_instance ? aws_spot_instance_request.openclaw[0].id : null
}

output "start_openclaw_command" {
  description = "Command to start OpenClaw container after connecting via SSM"
  value       = <<-EOT
    docker run -d --name openclaw --restart unless-stopped \
      -e DISCORD_TOKEN="your-token" \
      -v /opt/openclaw/data:/app/data \
      -v /opt/openclaw/logs:/app/logs \
      ghcr.io/openclaw/openclaw:latest
  EOT
}
