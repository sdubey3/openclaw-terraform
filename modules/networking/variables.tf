variable "vpc_id" {
  description = "VPC ID where security groups will be created"
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

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "dashboard_allowed_ip" {
  description = "IP address (CIDR format) allowed to access OpenClaw dashboard on port 18789. Leave empty for no inbound access."
  type        = string
  default     = ""
}
