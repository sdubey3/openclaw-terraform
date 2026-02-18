output "instance_id" {
  description = "EC2 on-demand instance ID"
  value       = local.instance_id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = local.instance_public_ip
}
