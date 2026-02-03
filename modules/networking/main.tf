# Random suffix to avoid naming conflicts on multiple deployments
resource "random_id" "suffix" {
  byte_length = 4
}

# Security group for OpenClaw EC2 instance
resource "aws_security_group" "openclaw" {
  name        = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  description = "Security group for OpenClaw Discord bot"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}

# Allow all outbound traffic (required for Discord API, package updates, etc.)
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.openclaw.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-all-outbound"
  }
}

# Conditional inbound access to OpenClaw dashboard (port 18789)
# Only created when dashboard_allowed_ip is specified
resource "aws_vpc_security_group_ingress_rule" "dashboard_access" {
  count = var.dashboard_allowed_ip != "" ? 1 : 0

  security_group_id = aws_security_group.openclaw.id
  description       = "Allow dashboard access from specified IP"
  ip_protocol       = "tcp"
  from_port         = 18789
  to_port           = 18789
  cidr_ipv4         = var.dashboard_allowed_ip

  tags = {
    Name = "${var.project_name}-dashboard-access"
  }
}

# EFS security group
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-${var.environment}-${random_id.suffix.hex}"
  description = "Security group for OpenClaw EFS"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-efs-${var.environment}"
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
