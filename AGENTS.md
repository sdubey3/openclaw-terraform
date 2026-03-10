# OpenClaw Terraform Infrastructure

## Project Overview

This repository contains Terraform infrastructure for hosting [OpenClaw](https://github.com/openclaw/openclaw) on dedicated AWS infrastructure. OpenClaw is a self-hosted, privacy-first personal AI assistant that:

- Runs locally on your machine (Mac, Windows, Linux)
- Integrates with WhatsApp, Telegram, Discord, Slack, Signal, iMessage
- Can browse web, manage calendar, handle emails, execute commands
- Uses Node.js 22+, and a WebSocket-based gateway architecture

The infrastructure deploys an EC2 instance (Ubuntu 24.04) with OpenClaw installed directly via npm, persistent EFS storage, CloudWatch monitoring, and SSH access.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                     Default VPC                       │
│  ┌────────────────────────────────────────────────┐   │
│  │               EC2 Instance                     │   │
│  │  Ubuntu 24.04 (t3.medium)                      │   │
│  │  - Node.js 22 + OpenClaw (npm global)          │   │
│  │  - systemd service (openclaw-gateway)          │   │
│  │  - CloudWatch Agent                            │   │
│  │  - SSH access (port 22) + SSM fallback         │   │
│  └────────────────────────────────────────────────┘   │
│                         │                             │
│  ┌────────────────────────────────────────────────┐   │
│  │                 EFS Mount                      │   │
│  │  /opt/openclaw/.openclaw (config, workspace)   │   │
│  └────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
                          │
                          ▼
                    ┌──────────┐
                    │CloudWatch│
                    │Logs/Alarms│
                    └──────────┘
```

### Security Features

- **SSH access** - Terraform-managed key pair, restricted by CIDR
- **SSM Session Manager** - Fallback access (no SSH key needed)
- **VPC Flow Logs** - Network traffic monitoring
- **Security Groups** - SSH and dashboard access restricted by IP whitelist
- **SSM Parameter Store** - Secure secrets management (see `docs/secrets.md`)

## Repository Structure

```
openclaw-terraform/
├── environments/production/    # Main Terraform configuration
│   ├── main.tf                 # Module composition
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Outputs (SSH/SSM commands, etc.)
│   ├── providers.tf            # AWS provider config
│   └── versions.tf             # Terraform version constraints
├── modules/
│   ├── bootstrap/              # S3 state bucket setup
│   ├── compute/                # EC2 instance with direct OpenClaw install
│   ├── networking/             # Security groups, VPC Flow Logs
│   ├── storage/                # EFS persistent storage
│   ├── iam/                    # Roles, policies, instance profiles
│   └── monitoring/             # CloudWatch alarms, SNS alerts
├── templates/
│   └── user_data.sh.tftpl      # EC2 bootstrap script (Ubuntu 24.04)
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
cd environments/production

# Configure backend with your AWS account ID
cp backend.tfbackend.example backend.tfbackend
# Edit backend.tfbackend with your AWS account ID

# Initialize Terraform
terraform init -backend-config=backend.tfbackend

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply

# Get connection commands
terraform output ssh_connect_command
terraform output ssm_connect_command
```

## Module Reference

| Module | Purpose |
|--------|---------|
| `bootstrap` | Creates S3 bucket for Terraform state with versioning and encryption |
| `compute` | EC2 instance with Ubuntu 24.04, Node.js 22, OpenClaw via npm |
| `networking` | Security groups (EC2, EFS), VPC Flow Logs to CloudWatch |
| `storage` | EFS file system with mount target and automatic backups |
| `iam` | IAM role, instance profile, policies for SSM, CloudWatch |
| `monitoring` | CloudWatch alarms (instance status, memory), SNS topic for alerts |

## Post-Deployment Setup

1. **Connect to the instance:**
   ```bash
   ssh -i <your-private-key> ubuntu@<instance-public-ip>
   ```

   Or via SSM:
   ```bash
   aws ssm start-session --target <instance-id> --region us-east-1 --profile admin
   ```

2. **Run the setup helper (first time only):**
   ```bash
   openclaw-setup
   ```

   This runs `openclaw onboard` (interactive) and starts the systemd service.

3. **Access the Control UI:**
   - URL: `http://127.0.0.1:18789/`
   - Paste the token from `/opt/openclaw/.openclaw/.env` into Settings

### Data Persistence

**EFS Storage:**
- Config directory: `/opt/openclaw/.openclaw` (OpenClaw config, skills, memories)
- Symlinked from `/home/ubuntu/.openclaw`
- Automatic backups via AWS Backup (EFS backup policy enabled)

**Local disk:**
- Playwright browsers at `~/.cache/ms-playwright/` (reinstalled on instance replacement, ~2-3 min)
- npm global packages on root EBS

### Automatic Resume on Instance Restart

OpenClaw automatically resumes after instance restarts (reboots or recreation) without manual intervention.

**How It Works:**

When an instance launches, the user_data script:
1. Installs Node.js 22 and OpenClaw via npm
2. Mounts EFS with persistent config
3. Detects existing `.env` and `openclaw.json`
4. Starts the gateway via `systemctl enable --now openclaw-gateway`
5. Typical resume time: 5-7 minutes

**Verification:**

Check if auto-resume succeeded:
```bash
# View user-data logs
aws logs tail /openclaw/production/user-data --follow --profile admin

# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace "OpenClaw" \
  --metric-name "InstanceResumeSuccess" \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region us-east-1 \
  --profile admin
```

**Manual Override:**

To stop/restart the gateway:
```bash
ssh -i <key> ubuntu@<ip>
sudo systemctl stop openclaw-gateway
sudo systemctl start openclaw-gateway
journalctl -u openclaw-gateway -f
```

**Troubleshooting:**

If auto-resume fails:
1. Check logs in CloudWatch: `/openclaw/production/user-data`
2. Look for `InstanceResumeFailure` metric with reason dimension
3. Common issues:
   - Missing or corrupted `.env` file
   - Missing gateway token
   - Port 18789 already in use
4. Manual recovery: SSH in and run `openclaw-setup`

**First-Time Setup:**

Auto-resume only works after initial onboarding. For first deployment:
1. Follow standard setup instructions in "Post-Deployment Setup"
2. Complete onboarding via `openclaw-setup`
3. After onboarding, all future instance restarts will auto-resume

### Remote Dashboard Access (Optional)

By default, the OpenClaw dashboard is only accessible locally. To enable remote access from your IP:

1. **Configure your IP address:**
   ```hcl
   # In environments/production/terraform.tfvars
   dashboard_allowed_ip = "203.0.113.1/32"
   ```

2. **Apply the change:**
   ```bash
   cd environments/production
   terraform apply
   ```

3. **Access the dashboard:**
   - Get your instance's public IP: `terraform output -raw instance_public_ip`
   - Open: `http://<instance-public-ip>:18789/`
   - Enter the gateway token from your OpenClaw setup

**Security Note:** Only the specified IP address can access the dashboard. To disable remote access, set `dashboard_allowed_ip = ""` and run `terraform apply`.

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
| `root_volume_size` | `20` | Root EBS volume size in GB (8-100) |
| `environment` | `production` | Environment tag |
| `project_name` | `openclaw` | Project name for resource naming |
| `alert_email` | `""` | Email for CloudWatch alert notifications |
| `public_key` | `""` | SSH public key content for EC2 access |
| `ssh_allowed_cidr` | `""` | CIDR block for SSH access (port 22) |
| `dashboard_allowed_ip` | `""` | IP address (CIDR) for dashboard access (port 18789) |
| `install_playwright_browsers` | `true` | Auto-install Playwright browsers on resume |
