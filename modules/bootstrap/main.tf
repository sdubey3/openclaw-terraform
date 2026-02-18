# S3 bucket for Terraform state
# Note: Terraform 1.10+ supports native S3 locking via use_lockfile = true
# No DynamoDB table needed - state locking uses S3 conditional writes
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-${var.aws_account_id}"

  tags = {
    Name = "${var.project_name}-terraform-state"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Block public access to state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for state recovery
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for state
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
