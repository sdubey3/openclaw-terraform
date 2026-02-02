terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote S3 backend with native S3 locking (Terraform 1.10+)
  # To migrate from local state:
  # 1. First apply the bootstrap module to create S3 bucket
  # 2. Then run: terraform init -migrate-state
  backend "s3" {
    bucket       = "openclaw-terraform-state-338066022177"
    key          = "production/terraform.tfstate"
    region       = "us-east-1"
    profile      = "admin" # AWS SSO profile
    encrypt      = true
    use_lockfile = true # Native S3 locking - no DynamoDB needed
  }
}
