# EFS file system for persistent OpenClaw data
resource "aws_efs_file_system" "openclaw_data" {
  creation_token   = "${var.project_name}-${var.environment}"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.project_name}-data-${var.environment}"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# EFS mount target
resource "aws_efs_mount_target" "openclaw" {
  file_system_id  = aws_efs_file_system.openclaw_data.id
  subnet_id       = var.subnet_id
  security_groups = [var.efs_security_group_id]
}

# EFS backup policy
resource "aws_efs_backup_policy" "openclaw" {
  file_system_id = aws_efs_file_system.openclaw_data.id
  backup_policy {
    status = "ENABLED"
  }
}
