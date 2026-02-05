# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Data source for default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source for default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Get the first available subnet
data "aws_subnet" "selected" {
  id = data.aws_subnets.default.ids[0]
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Networking module - no dependencies
module "networking" {
  source = "../../modules/networking"

  vpc_id               = data.aws_vpc.default.id
  environment          = var.environment
  project_name         = var.project_name
  dashboard_allowed_ip = var.dashboard_allowed_ip
}

# Storage module - depends on networking for EFS security group
module "storage" {
  source = "../../modules/storage"

  environment           = var.environment
  project_name          = var.project_name
  subnet_id             = data.aws_subnet.selected.id
  efs_security_group_id = module.networking.efs_security_group_id
}

# IAM module
module "iam" {
  source = "../../modules/iam"

  environment    = var.environment
  project_name   = var.project_name
  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
}

# Compute module - depends on all other modules
# depends_on ensures EFS mount target DNS is ready before instance boots
# Full container mode is always enabled (persistent /home/node, Homebrew, CLI tools, Playwright)
module "compute" {
  source = "../../modules/compute"

  ami_id                = data.aws_ami.amazon_linux_2023.id
  instance_type         = var.instance_type
  subnet_id             = data.aws_subnet.selected.id
  security_group_id     = module.networking.ec2_security_group_id
  instance_profile_name = module.iam.instance_profile_name
  efs_id                = module.storage.efs_id
  environment           = var.environment
  project_name          = var.project_name
  aws_region            = var.aws_region
  root_volume_size      = var.root_volume_size

  # Full-featured container support (always enabled)
  openclaw_home_volume         = var.openclaw_home_volume
  openclaw_docker_apt_packages = var.openclaw_docker_apt_packages
  install_playwright_browsers  = var.install_playwright_browsers

  depends_on = [module.storage]
}

# Monitoring module - depends on compute and storage
module "monitoring" {
  source = "../../modules/monitoring"

  environment  = var.environment
  project_name = var.project_name
  instance_id  = module.compute.instance_id
  alert_email  = var.alert_email
}
