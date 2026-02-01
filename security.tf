# Security group for OpenClaw EC2 instance
resource "aws_security_group" "openclaw" {
  name        = "openclaw-${var.environment}"
  description = "Security group for OpenClaw Discord bot"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "openclaw-${var.environment}"
  }
}

# Allow all outbound traffic (required for Discord API, package updates, etc.)
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.openclaw.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "openclaw-all-outbound"
  }
}

# EFS security group
resource "aws_security_group" "efs" {
  name        = "openclaw-efs-${var.environment}"
  description = "Security group for OpenClaw EFS"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "openclaw-efs-${var.environment}"
  }
}

# NFS ingress from EC2
resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  security_group_id            = aws_security_group.efs.id
  description                  = "NFS from OpenClaw EC2"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.openclaw.id
}
