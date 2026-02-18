# SNS topic for alerts
resource "aws_sns_topic" "openclaw_alerts" {
  name = "${var.project_name}-alerts-${var.environment}"

  tags = {
    Name = "${var.project_name}-alerts-${var.environment}"
  }
}

# SNS email subscription (only created if alert_email is provided)
resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.openclaw_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# SNS topic policy
resource "aws_sns_topic_policy" "openclaw_alerts" {
  arn = aws_sns_topic.openclaw_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.openclaw_alerts.arn
      }
    ]
  })
}

# CloudWatch alarm for EC2 instance status check
resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "${var.project_name}-instance-status-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 instance status check failed"
  alarm_actions       = [aws_sns_topic.openclaw_alerts.arn]
  ok_actions          = [aws_sns_topic.openclaw_alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = {
    Name = "${var.project_name}-instance-status-${var.environment}"
  }
}

# CloudWatch alarm for high memory utilization
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.project_name}-high-memory-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "mem_used_percent"
  namespace           = "OpenClaw"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Memory utilization is above 80%"
  alarm_actions       = [aws_sns_topic.openclaw_alerts.arn]
  ok_actions          = [aws_sns_topic.openclaw_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId  = var.instance_id
    Environment = var.environment
  }

  tags = {
    Name = "${var.project_name}-high-memory-${var.environment}"
  }
}
