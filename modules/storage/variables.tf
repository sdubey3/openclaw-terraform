variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "openclaw"
}

variable "subnet_id" {
  description = "Subnet ID for EFS mount target"
  type        = string
}

variable "efs_security_group_id" {
  description = "Security group ID for EFS mount target"
  type        = string
}
