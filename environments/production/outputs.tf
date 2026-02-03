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

locals {
  setup_instructions_full = <<-EOT
    # OpenClaw Docker Compose Setup Instructions (Full Container Mode)
    #
    # 1. Connect to the instance:
    aws ssm start-session --target ${module.compute.instance_id} --region ${var.aws_region} --profile admin

    # 2. Run the Docker setup script (as ec2-user):
    cd /opt/openclaw/openclaw-docker
    ./docker-setup.sh

    # The script will:
    #   - Build the Docker image
    #   - Run the onboarding wizard
    #   - Generate a gateway token (saved to .env)
    #   - Start the gateway

    # 3. Install Playwright browsers (for web automation):
    ./install-playwright.sh

    # 4. Access the Control UI:
    # http://127.0.0.1:18789/
    # Paste the token from .env into Settings

    # Full container features enabled:
    #   - Persistent /home/node via Docker volume: ${var.openclaw_home_volume}
    #   - Playwright system dependencies installed
    #   - Browsers auto-installed on spot instance replacement

    # Config persisted at: /opt/openclaw/.openclaw (on EFS)
    # Daily backups to S3: ${module.storage.s3_bucket_name}
  EOT

  setup_instructions_standard = <<-EOT
    # OpenClaw Docker Compose Setup Instructions
    #
    # 1. Connect to the instance:
    aws ssm start-session --target ${module.compute.instance_id} --region ${var.aws_region} --profile admin

    # 2. Run the Docker setup script (as ec2-user):
    cd /opt/openclaw/openclaw-docker
    ./docker-setup.sh

    # The script will:
    #   - Build the Docker image
    #   - Run the onboarding wizard
    #   - Generate a gateway token (saved to .env)
    #   - Start the gateway

    # 3. Access the Control UI:
    # http://127.0.0.1:18789/
    # Paste the token from .env into Settings

    # Config persisted at: /opt/openclaw/.openclaw (on EFS)
    # Daily backups to S3: ${module.storage.s3_bucket_name}
  EOT
}

output "setup_instructions" {
  description = "Instructions to complete OpenClaw setup after connecting via SSM"
  value       = var.enable_full_container ? local.setup_instructions_full : local.setup_instructions_standard
}
