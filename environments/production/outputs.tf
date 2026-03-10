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

output "ssh_connect_command" {
  description = "Connect via SSH (requires public_key and ssh_allowed_cidr to be configured)"
  value       = "ssh -i <your-private-key> ubuntu@${module.compute.public_ip}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.networking.ec2_security_group_id
}

output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = module.storage.efs_id
}

locals {
  setup_instructions = <<-EOT
    # OpenClaw Setup Instructions (Ubuntu 24.04, runs as root)
    #
    # 1. Connect via SSM:
    aws ssm start-session --target ${module.compute.instance_id} --region ${var.aws_region}
    # Then: sudo -i
    #
    # Or via SSH:
    ssh -i <your-private-key> ubuntu@${module.compute.public_ip}
    # Then: sudo -i

    # 2. Run onboarding (first time only):
    openclaw onboard --install-daemon

    # 3. Access the Control UI via SSH tunnel:
    # ssh -i <your-private-key> -L 18789:127.0.0.1:18789 ubuntu@${module.compute.public_ip}
    # Then open: http://127.0.0.1:18789/
    # Paste the token from /root/.openclaw/.env into Settings

    # Useful commands:
    #   XDG_RUNTIME_DIR=/run/user/0 systemctl --user status openclaw-gateway
    #   XDG_RUNTIME_DIR=/run/user/0 journalctl --user -u openclaw-gateway -f
    #   XDG_RUNTIME_DIR=/run/user/0 systemctl --user restart openclaw-gateway

    # Paths:
    #   Config:    /root/.openclaw → /opt/openclaw/.openclaw (EFS)
    #   Workspace: /opt/openclaw/workspace (EFS)
  EOT
}

output "setup_instructions" {
  description = "Instructions to complete OpenClaw setup after connecting"
  value       = local.setup_instructions
}
