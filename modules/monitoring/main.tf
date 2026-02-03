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

# CloudWatch alarm for EFS burst credit balance
resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_balance" {
  alarm_name          = "${var.project_name}-efs-burst-credits-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BurstCreditBalance"
  namespace           = "AWS/EFS"
  period              = 300
  statistic           = "Average"
  threshold           = 1000000000000 # 1 TB of burst credits (low warning)
  alarm_description   = "EFS burst credit balance is low"
  alarm_actions       = [aws_sns_topic.openclaw_alerts.arn]
  ok_actions          = [aws_sns_topic.openclaw_alerts.arn]

  dimensions = {
    FileSystemId = var.efs_id
  }

  tags = {
    Name = "${var.project_name}-efs-burst-credits-${var.environment}"
  }
}

# CloudWatch alarm for user data setup failure
resource "aws_cloudwatch_metric_alarm" "user_data_failure" {
  alarm_name          = "${var.project_name}-user-data-failure-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UserDataFailure"
  namespace           = "OpenClaw"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "EC2 user data script failed"
  alarm_actions       = [aws_sns_topic.openclaw_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
  }

  tags = {
    Name = "${var.project_name}-user-data-failure-${var.environment}"
  }
}

# CloudWatch alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization is above 80%"
  alarm_actions       = [aws_sns_topic.openclaw_alerts.arn]
  ok_actions          = [aws_sns_topic.openclaw_alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = {
    Name = "${var.project_name}-high-cpu-${var.environment}"
  }
}

# CloudWatch alarm for backup failures
resource "aws_cloudwatch_metric_alarm" "backup_failure" {
  alarm_name          = "${var.project_name}-backup-failure-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BackupFailure"
  namespace           = "OpenClaw"
  period              = 86400 # 24 hours
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "OpenClaw backup failed"
  alarm_actions       = [aws_sns_topic.openclaw_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
  }

  tags = {
    Name = "${var.project_name}-backup-failure-${var.environment}"
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

# CloudWatch alarm for instance resume failures
resource "aws_cloudwatch_metric_alarm" "instance_resume_failure" {
  alarm_name          = "${var.project_name}-instance-resume-failure-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "InstanceResumeFailure"
  namespace           = "OpenClaw"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when OpenClaw instance resume fails"
  treat_missing_data  = "notBreaching"

  dimensions = {
    Environment = var.environment
  }

  alarm_actions = [aws_sns_topic.openclaw_alerts.arn]

  tags = {
    Name = "${var.project_name}-instance-resume-failure-${var.environment}"
  }
}
