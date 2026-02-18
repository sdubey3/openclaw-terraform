variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "openclaw"
}

variable "instance_id" {
  description = "EC2 instance ID for monitoring"
  type        = string
}

variable "alert_email" {
  description = "Email address for alert notifications (optional)"
  type        = string
  default     = ""
}
