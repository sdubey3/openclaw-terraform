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

  vpc_id       = data.aws_vpc.default.id
  environment  = var.environment
  project_name = var.project_name
}

# Storage module - depends on networking for EFS security group
module "storage" {
  source = "../../modules/storage"

  environment           = var.environment
  project_name          = var.project_name
  subnet_id             = data.aws_subnet.selected.id
  efs_security_group_id = module.networking.efs_security_group_id
}

# IAM module - depends on storage for S3 bucket ARN
module "iam" {
  source = "../../modules/iam"

  environment    = var.environment
  project_name   = var.project_name
  s3_bucket_arn  = module.storage.s3_bucket_arn
  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
}

# Compute module - depends on all other modules
# depends_on ensures EFS mount target DNS is ready before instance boots
module "compute" {
  source = "../../modules/compute"

  ami_id                = data.aws_ami.amazon_linux_2023.id
  instance_type         = var.instance_type
  subnet_id             = data.aws_subnet.selected.id
  security_group_id     = module.networking.ec2_security_group_id
  instance_profile_name = module.iam.instance_profile_name
  efs_id                = module.storage.efs_id
  s3_bucket_name        = module.storage.s3_bucket_name
  use_spot_instance     = var.use_spot_instance
  spot_max_price        = var.spot_max_price
  environment           = var.environment
  project_name          = var.project_name
  aws_region            = var.aws_region

  depends_on = [module.storage]
}

# Monitoring module - depends on compute and storage
module "monitoring" {
  source = "../../modules/monitoring"

  environment  = var.environment
  project_name = var.project_name
  instance_id  = module.compute.instance_id
  efs_id       = module.storage.efs_id
}
