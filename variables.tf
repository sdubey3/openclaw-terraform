variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "production"
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
