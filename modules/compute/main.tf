# On-demand instance for OpenClaw bot (full container mode always enabled)
resource "aws_instance" "openclaw" {

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name

  user_data = base64encode(templatefile("${path.module}/../../templates/user_data.sh.tftpl", {
    efs_id                       = var.efs_id
    mount_point                  = "/opt/openclaw"
    aws_region                   = var.aws_region
    project_name                 = var.project_name
    environment                  = var.environment
    openclaw_home_volume         = var.openclaw_home_volume
    openclaw_docker_apt_packages = var.openclaw_docker_apt_packages
    install_playwright_browsers  = var.install_playwright_browsers
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

locals {
  instance_id        = aws_instance.openclaw.id
  instance_public_ip = aws_instance.openclaw.public_ip
}
