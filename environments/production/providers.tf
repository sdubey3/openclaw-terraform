provider "aws" {
  region  = var.aws_region
  profile = "admin" # AWS SSO profile

  default_tags {
    tags = {
      Project     = "OpenClaw"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
