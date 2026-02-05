variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "openclaw"
}

variable "aws_region" {
  description = "AWS region for SSM parameter ARN construction"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for SSM parameter ARN construction"
  type        = string
}
