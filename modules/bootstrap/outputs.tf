output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "backend_config" {
  description = "Backend configuration to add to versions.tf"
  value       = <<-EOT
    # Add this to your versions.tf after running terraform init -migrate-state
    backend "s3" {
      bucket       = "${aws_s3_bucket.terraform_state.id}"
      key          = "production/terraform.tfstate"
      region       = "${var.aws_region}"
      encrypt      = true
      use_lockfile = true  # Native S3 locking - no DynamoDB needed
    }
  EOT
}
