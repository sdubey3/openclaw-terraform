variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "openclaw"
}

variable "aws_account_id" {
  description = "AWS account ID (used for unique bucket naming)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
