# Spot instance for OpenClaw bot
resource "aws_spot_instance_request" "openclaw" {
  count = var.use_spot_instance ? 1 : 0

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name

  spot_type                      = "persistent"
  instance_interruption_behavior = "stop"
  wait_for_fulfillment           = true
  spot_price                     = var.spot_max_price != "" ? var.spot_max_price : null

  user_data = base64encode(templatefile("${path.module}/../../templates/user_data.sh.tftpl", {
    efs_id                       = var.efs_id
    mount_point                  = "/opt/openclaw"
    s3_bucket                    = var.s3_bucket_name
    aws_region                   = var.aws_region
    project_name                 = var.project_name
    environment                  = var.environment
    enable_full_container        = var.enable_full_container
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

# On-demand instance fallback
resource "aws_instance" "openclaw" {
  count = var.use_spot_instance ? 0 : 1

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name

  user_data = base64encode(templatefile("${path.module}/../../templates/user_data.sh.tftpl", {
    efs_id                       = var.efs_id
    mount_point                  = "/opt/openclaw"
    s3_bucket                    = var.s3_bucket_name
    aws_region                   = var.aws_region
    project_name                 = var.project_name
    environment                  = var.environment
    enable_full_container        = var.enable_full_container
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
  instance_id        = var.use_spot_instance ? aws_spot_instance_request.openclaw[0].spot_instance_id : aws_instance.openclaw[0].id
  instance_public_ip = var.use_spot_instance ? aws_spot_instance_request.openclaw[0].public_ip : aws_instance.openclaw[0].public_ip
}
