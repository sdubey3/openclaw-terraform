output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.openclaw_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alerts"
  value       = aws_sns_topic.openclaw_alerts.name
}
