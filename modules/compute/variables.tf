variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
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

# Full-featured container variables (always enabled)
variable "openclaw_home_volume" {
  description = "Docker named volume for persistent /home/node in the container"
  type        = string
  default     = "openclaw_home"
}

variable "openclaw_docker_apt_packages" {
  description = "Space-separated list of APT packages to install in the Docker image for Playwright support"
  type        = string
  default     = ""
}

variable "install_playwright_browsers" {
  description = "Automatically install Playwright browsers on auto-resume"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}
