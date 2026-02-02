variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^t[34][ag]?\\.(micro|small|medium|large|xlarge)$", var.instance_type))
    error_message = "Instance type must be t3, t3a, t4g, or t4a in sizes micro, small, medium, large, or xlarge."
  }
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "openclaw"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project_name))
    error_message = "Project name must start with a letter, be lowercase alphanumeric with hyphens, and 2-21 characters."
  }
}

variable "use_spot_instance" {
  description = "Use spot instance for cost savings"
  type        = bool
  default     = true
}

variable "spot_max_price" {
  description = "Maximum hourly price (empty = on-demand price cap)"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for CloudWatch alert notifications"
  type        = string
  default     = ""
}
