output "instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the OpenClaw EC2 instance"
  value       = module.compute.public_ip
}

output "s3_bucket_name" {
  description = "S3 bucket name for backups"
  value       = module.storage.s3_bucket_name
}

output "ssm_connect_command" {
  description = "Connect via SSM Session Manager"
  value       = "aws ssm start-session --target ${module.compute.instance_id} --region ${var.aws_region}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.networking.ec2_security_group_id
}

output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = module.storage.efs_id
}

output "spot_request_id" {
  description = "Spot request ID (if using spot)"
  value       = module.compute.spot_request_id
}

output "vpc_flow_log_group" {
  description = "CloudWatch log group name for VPC Flow Logs"
  value       = module.networking.flow_log_group_name
}

output "cloudtrail_bucket" {
  description = "S3 bucket for CloudTrail logs"
  value       = module.cloudtrail.s3_bucket_name
}

output "setup_instructions" {
  description = "Instructions to complete OpenClaw setup after connecting via SSM"
  value       = <<-EOT
    # OpenClaw Setup Instructions
    #
    # 1. Connect to the instance:
    aws ssm start-session --target ${module.compute.instance_id} --region ${var.aws_region} --profile admin

    # 2. Install OpenClaw (run on the instance as ec2-user):
    npm install -g openclaw@latest
    openclaw onboard --install-daemon

    # Your OpenClaw config will persist at /opt/openclaw/.openclaw (on EFS)
    # Daily backups to S3: ${module.storage.s3_bucket_name}
  EOT
}
