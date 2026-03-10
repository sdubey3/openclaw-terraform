# Data source for latest Ubuntu 24.04 AMI
data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
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

# SSH key pair (only created when public_key is provided)
resource "aws_key_pair" "openclaw" {
  count = var.public_key != "" ? 1 : 0

  key_name   = "${var.project_name}-${var.environment}"
  public_key = var.public_key
}

# Networking module - no dependencies
module "networking" {
  source = "../../modules/networking"

  vpc_id               = data.aws_vpc.default.id
  environment          = var.environment
  project_name         = var.project_name
  dashboard_allowed_ip = var.dashboard_allowed_ip
  ssh_allowed_cidr     = var.ssh_allowed_cidr
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
module "compute" {
  source = "../../modules/compute"

  ami_id                = data.aws_ami.ubuntu_2404.id
  instance_type         = var.instance_type
  subnet_id             = data.aws_subnet.selected.id
  security_group_id     = module.networking.ec2_security_group_id
  instance_profile_name = module.iam.instance_profile_name
  efs_id                = module.storage.efs_id
  environment           = var.environment
  project_name          = var.project_name
  aws_region            = var.aws_region
  root_volume_size      = var.root_volume_size
  key_name              = var.public_key != "" ? aws_key_pair.openclaw[0].key_name : ""

  depends_on = [module.storage]
}
