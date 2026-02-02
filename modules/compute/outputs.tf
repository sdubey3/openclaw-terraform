output "instance_id" {
  description = "EC2 instance ID"
  value       = local.instance_id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = local.instance_public_ip
}

output "spot_request_id" {
  description = "Spot request ID (if using spot)"
  value       = var.use_spot_instance ? aws_spot_instance_request.openclaw[0].id : null
}
