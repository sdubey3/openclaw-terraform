output "instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the OpenClaw EC2 instance"
  value       = module.compute.public_ip
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

output "vpc_flow_log_group" {
  description = "CloudWatch log group name for VPC Flow Logs"
  value       = module.networking.flow_log_group_name
}

locals {
  setup_instructions = <<-EOT
    # OpenClaw Docker Compose Setup Instructions (Full Container Mode - Always Enabled)
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

    # Full container features (always enabled):
    #   - Persistent /home/node via Docker volume: ${var.openclaw_home_volume}
    #   - Homebrew, CLI tools, and auth tokens persist across rebuilds
    #   - Playwright browsers auto-install on instance restart

    # Config persisted at: /opt/openclaw/.openclaw (on EFS)
    # EFS automatic backups enabled via AWS Backup
  EOT
}

output "setup_instructions" {
  description = "Instructions to complete OpenClaw setup after connecting via SSM"
  value       = local.setup_instructions
}
