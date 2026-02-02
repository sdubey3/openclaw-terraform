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

# S3 bucket for backups
resource "aws_s3_bucket" "openclaw_backups" {
  bucket_prefix = "${var.project_name}-backups-"

  tags = {
    Name = "${var.project_name}-backups-${var.environment}"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "openclaw_backups" {
  bucket = aws_s3_bucket.openclaw_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for backup protection
resource "aws_s3_bucket_versioning" "openclaw_backups" {
  bucket = aws_s3_bucket.openclaw_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "openclaw_backups" {
  bucket = aws_s3_bucket.openclaw_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rules for cost management
resource "aws_s3_bucket_lifecycle_configuration" "openclaw_backups" {
  bucket = aws_s3_bucket.openclaw_backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    # Move to Glacier after 30 days
    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    # Delete after 90 days
    expiration {
      days = 90
    }

    # Clean up old versions
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
