# IAM role for EC2 instance
resource "aws_iam_role" "openclaw" {
  name = "openclaw-ec2-role-${var.environment}"

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
    Name = "openclaw-ec2-role-${var.environment}"
  }
}

# IAM policy for S3 bucket access (least privilege)
resource "aws_iam_policy" "openclaw_s3" {
  name        = "openclaw-s3-access-${var.environment}"
  description = "Allow OpenClaw EC2 instance to access backup S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.openclaw_backups.arn
      },
      {
        Sid    = "ReadWriteObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.openclaw_backups.arn}/*"
      }
    ]
  })
}

# Attach S3 policy to role
resource "aws_iam_role_policy_attachment" "openclaw_s3" {
  role       = aws_iam_role.openclaw.name
  policy_arn = aws_iam_policy.openclaw_s3.arn
}

# Attach SSM policy for optional session manager access
resource "aws_iam_role_policy_attachment" "openclaw_ssm" {
  role       = aws_iam_role.openclaw.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM instance profile
resource "aws_iam_instance_profile" "openclaw" {
  name = "openclaw-instance-profile-${var.environment}"
  role = aws_iam_role.openclaw.name
}
