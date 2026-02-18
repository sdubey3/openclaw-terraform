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

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 8 and 100 GB."
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

variable "alert_email" {
  description = "Email address for CloudWatch alert notifications"
  type        = string
  default     = ""
}

variable "dashboard_allowed_ip" {
  description = "IP address (CIDR format) allowed to access OpenClaw dashboard on port 18789. Leave empty for no inbound access (SSM only). Use /32 suffix for single IP (e.g., 203.0.113.1/32)."
  type        = string
  default     = ""

  validation {
    condition     = var.dashboard_allowed_ip == "" || can(cidrhost(var.dashboard_allowed_ip, 0))
    error_message = "Dashboard allowed IP must be empty or a valid CIDR notation (e.g., 203.0.113.1/32 for single IP)."
  }
}

# Full-featured container variables (always enabled)
variable "openclaw_home_volume" {
  description = "Docker named volume for persistent /home/node in the container"
  type        = string
  default     = "openclaw_home"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_-]{0,63}$", var.openclaw_home_volume))
    error_message = "Volume name must start with a letter and contain only lowercase letters, numbers, underscores, and hyphens (max 64 chars)."
  }
}

variable "openclaw_docker_apt_packages" {
  description = "Space-separated list of APT packages to install in the Docker image for Playwright support"
  type        = string
  default     = "libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2"
}

variable "install_playwright_browsers" {
  description = "Automatically install Playwright browsers on auto-resume"
  type        = bool
  default     = true
}
