# OpenClaw Terraform Infrastructure

## Project Overview

This repository contains Terraform infrastructure for hosting [OpenClaw](https://github.com/openclaw/openclaw) on dedicated AWS infrastructure. OpenClaw is a self-hosted, privacy-first personal AI assistant that:

- Runs locally on your machine (Mac, Windows, Linux)
- Integrates with WhatsApp, Telegram, Discord, Slack, Signal, iMessage
- Can browse web, manage calendar, handle emails, execute commands
- Uses Node.js 22+, Docker, and a WebSocket-based gateway architecture

The infrastructure deploys a cost-optimized EC2 instance (Spot by default) with persistent EFS storage, automated backups to S3, and comprehensive monitoring.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Default VPC                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    EC2 Instance                      │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │  Amazon Linux 2023 (t3.medium Spot)            │  │   │
│  │  │  - Docker + Docker Compose                     │  │   │
│  │  │  - Node.js 22                                  │  │   │
│  │  │  - OpenClaw Gateway (port 18789)               │  │   │
│  │  │  - CloudWatch Agent                            │  │   │
│  │  │  - SSM Agent (Session Manager access)          │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                            │                                 │
│                            ▼                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    EFS Mount                         │   │
│  │  /opt/openclaw/.openclaw (config, workspace)         │   │
│  │  /opt/openclaw/openclaw-docker (cloned repo)         │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────────┐
        │    S3    │  │CloudWatch│  │  CloudTrail  │
        │ Backups  │  │  Alarms  │  │ Audit Logs   │
        └──────────┘  └──────────┘  └──────────────┘
```

### Security Features

- **No SSH keys** - Access via SSM Session Manager only
- **VPC Flow Logs** - Network traffic monitoring
- **CloudTrail** - API audit logging
- **Security Groups** - Egress-only (no inbound from internet)
- **SSM Parameter Store** - Secure secrets management (see `docs/secrets.md`)
- **S3 encryption** - AES-256 for backups and state

## Repository Structure

```
openclaw-terraform/
├── environments/production/    # Main Terraform configuration
│   ├── main.tf                 # Module composition
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Outputs (SSM command, etc.)
│   ├── providers.tf            # AWS provider config
│   └── versions.tf             # Terraform version constraints
├── modules/
│   ├── bootstrap/              # S3 state bucket setup
│   ├── compute/                # EC2 Spot + On-Demand instances
│   ├── networking/             # Security groups, VPC Flow Logs
│   ├── storage/                # EFS + S3 backups
│   ├── iam/                    # Roles, policies, instance profiles
│   ├── monitoring/             # CloudWatch alarms, SNS alerts
│   └── cloudtrail/             # API audit logging
├── templates/
│   └── user_data.sh.tftpl      # EC2 bootstrap script
└── docs/
    └── secrets.md              # SSM Parameter Store guide
```

## Prerequisites

- **Terraform** >= 1.10 (uses native S3 state locking)
- **AWS CLI** v2
- **AWS SSO profile** named `admin` configured

```bash
# Configure AWS SSO
aws configure sso --profile admin

# Verify access
aws sts get-caller-identity --profile admin
```

## Quick Start

```bash
# Initialize Terraform
cd environments/production
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply

# Get the SSM connect command
terraform output ssm_connect_command
```

## Module Reference

| Module | Purpose |
|--------|---------|
| `bootstrap` | Creates S3 bucket for Terraform state with versioning and encryption |
| `compute` | EC2 instance (Spot or On-Demand), user data script, instance configuration |
| `networking` | Security groups (EC2, EFS), VPC Flow Logs to CloudWatch |
| `storage` | EFS file system with mount target, S3 bucket for daily backups |
| `iam` | IAM role, instance profile, policies for S3, SSM, CloudWatch |
| `monitoring` | CloudWatch alarms (CPU, disk, memory), SNS topic for alerts |
| `cloudtrail` | CloudTrail trail with dedicated S3 bucket for API audit logs |

## Post-Deployment Setup

1. **Connect to the instance:**
   ```bash
   aws ssm start-session --target <instance-id> --region us-east-1 --profile admin
   ```

2. **Run OpenClaw setup (as ec2-user):**
   ```bash
   cd /opt/openclaw/openclaw-docker
   ./docker-setup.sh
   ```

3. **The setup script will:**
   - Build the Docker image
   - Run the onboarding wizard (interactive)
   - Generate a gateway token (saved to `.env`)
   - Start the gateway

4. **Access the Control UI:**
   - URL: `http://127.0.0.1:18789/`
   - Paste the token from `.env` into Settings

### Data Persistence

- Config directory: `/opt/openclaw/.openclaw` (on EFS)
- Daily backups: Uploaded to S3 at 3 AM UTC
- Backup logs: `/var/log/openclaw-backup.log`

## Development Guidelines

### Terraform Conventions

- Use `terraform fmt` before committing
- Run `terraform validate` to check syntax
- All resources must have `environment` and `project_name` tags
- Variables should include validation blocks where applicable
- Use data sources for AMIs and existing VPC resources

### Code Style

- Module outputs should be descriptive and documented
- Use `locals` for computed values and repeated expressions
- Prefer explicit resource references over `depends_on` when possible
- Keep modules focused on a single responsibility

### Testing Changes

```bash
# Format check
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Plan with detailed output
terraform plan -out=tfplan

# Apply saved plan
terraform apply tfplan
```

## Important Rules

### Never Use `head` or `tail` Commands

When working with this repository, **never use `head` or `tail` commands** to read files. Use proper file reading tools instead. This applies to:

- Viewing Terraform files
- Reading logs
- Inspecting configuration

### Other Rules

- Never commit `.tfvars` files containing secrets
- Always use SSM Parameter Store for sensitive values
- Don't modify the bootstrap module after initial setup (state bucket)
- Keep the `admin` AWS SSO profile name consistent across environments

## Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region for deployment |
| `instance_type` | `t3.medium` | EC2 instance size |
| `environment` | `production` | Environment tag |
| `project_name` | `openclaw` | Project name for resource naming |
| `use_spot_instance` | `true` | Use Spot instance for cost savings |
| `spot_max_price` | `""` | Max hourly price (empty = on-demand cap) |
| `alert_email` | `""` | Email for CloudWatch alert notifications |
