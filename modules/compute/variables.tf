variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the EC2 instance"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "efs_id" {
  description = "EFS file system ID to mount"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for backups"
  type        = string
}

variable "use_spot_instance" {
  description = "Use spot instance for cost savings"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum hourly price for spot instance (empty = on-demand price cap)"
  type        = string
  default     = ""
}

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
  description = "AWS region for the user data script"
  type        = string
}
