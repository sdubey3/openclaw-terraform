# IAM role for EC2 instance
resource "aws_iam_role" "openclaw" {
  name = "${var.project_name}-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role-${var.environment}"
  }
}

# Attach SSM policy for session manager access
resource "aws_iam_role_policy_attachment" "openclaw_ssm" {
  role       = aws_iam_role.openclaw.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM policy for SSM Parameter Store access (secrets)
resource "aws_iam_policy" "openclaw_ssm_parameters" {
  name        = "${var.project_name}-ssm-parameters-${var.environment}"
  description = "Allow OpenClaw EC2 instance to read secrets from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.project_name}/${var.environment}/*"
      }
    ]
  })
}

# Attach SSM Parameter Store policy to role
resource "aws_iam_role_policy_attachment" "openclaw_ssm_parameters" {
  role       = aws_iam_role.openclaw.name
  policy_arn = aws_iam_policy.openclaw_ssm_parameters.arn
}

# IAM policy for CloudWatch Logs
resource "aws_iam_policy" "openclaw_cloudwatch_logs" {
  name        = "${var.project_name}-cloudwatch-logs-${var.environment}"
  description = "Allow OpenClaw EC2 instance to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateLogGroups"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"
      },
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/${var.project_name}/*:*"
      }
    ]
  })
}

# Attach CloudWatch Logs policy to role
resource "aws_iam_role_policy_attachment" "openclaw_cloudwatch_logs" {
  role       = aws_iam_role.openclaw.name
  policy_arn = aws_iam_policy.openclaw_cloudwatch_logs.arn
}

# IAM policy for CloudWatch custom metrics
resource "aws_iam_policy" "openclaw_cloudwatch_metrics" {
  name        = "${var.project_name}-cloudwatch-metrics-${var.environment}"
  description = "Allow OpenClaw EC2 instance to publish custom metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PutMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "OpenClaw"
          }
        }
      }
    ]
  })
}

# Attach CloudWatch metrics policy to role
resource "aws_iam_role_policy_attachment" "openclaw_cloudwatch_metrics" {
  role       = aws_iam_role.openclaw.name
  policy_arn = aws_iam_policy.openclaw_cloudwatch_metrics.arn
}

# IAM instance profile
resource "aws_iam_instance_profile" "openclaw" {
  name = "${var.project_name}-instance-profile-${var.environment}"
  role = aws_iam_role.openclaw.name
}
