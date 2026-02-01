# Spot instance for OpenClaw bot
resource "aws_spot_instance_request" "openclaw" {
  count = var.use_spot_instance ? 1 : 0

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.openclaw.id]
  iam_instance_profile   = aws_iam_instance_profile.openclaw.name

  spot_type                      = "persistent"
  instance_interruption_behavior = "stop"
  wait_for_fulfillment           = true
  spot_price                     = var.spot_max_price != "" ? var.spot_max_price : null

  depends_on = [aws_efs_mount_target.openclaw]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    efs_id      = aws_efs_file_system.openclaw_data.id
    mount_point = "/opt/openclaw"
    s3_bucket   = aws_s3_bucket.openclaw_backups.id
    aws_region  = var.aws_region
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "openclaw-${var.environment}"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# On-demand instance fallback
resource "aws_instance" "openclaw" {
  count = var.use_spot_instance ? 0 : 1

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.openclaw.id]
  iam_instance_profile   = aws_iam_instance_profile.openclaw.name

  depends_on = [aws_efs_mount_target.openclaw]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    efs_id      = aws_efs_file_system.openclaw_data.id
    mount_point = "/opt/openclaw"
    s3_bucket   = aws_s3_bucket.openclaw_backups.id
    aws_region  = var.aws_region
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "openclaw-${var.environment}"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

locals {
  instance_id        = var.use_spot_instance ? aws_spot_instance_request.openclaw[0].spot_instance_id : aws_instance.openclaw[0].id
  instance_public_ip = var.use_spot_instance ? aws_spot_instance_request.openclaw[0].public_ip : aws_instance.openclaw[0].public_ip
}
