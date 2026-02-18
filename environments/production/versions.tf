terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote S3 backend with native S3 locking (Terraform 1.10+)
  # Run: terraform init -backend-config=backend.tfbackend
  backend "s3" {
    key          = "production/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
