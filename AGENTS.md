# OpenClaw Terraform Infrastructure

## Project Overview

This repository contains Terraform infrastructure for hosting [OpenClaw](https://github.com/openclaw/openclaw) on dedicated AWS infrastructure. OpenClaw is a self-hosted, privacy-first personal AI assistant that:

- Runs locally on your machine (Mac, Windows, Linux)
- Integrates with WhatsApp, Telegram, Discord, Slack, Signal, iMessage
- Can browse web, manage calendar, handle emails, execute commands
- Uses Node.js 22+, Docker, and a WebSocket-based gateway architecture

The infrastructure deploys an EC2 instance (on-demand by default, with optional Spot support) with persistent EFS storage, Docker container logging to CloudWatch, and monitoring.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Default VPC                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    EC2 Instance                      │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │  Amazon Linux 2023 (t3.medium)                 │  │   │
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
                             ▼
                       ┌──────────┐
                       │CloudWatch│
                       │Logs/Alarms│
                       └──────────┘
```

### Security Features

- **No SSH keys** - Access via SSM Session Manager only
- **VPC Flow Logs** - Network traffic monitoring
- **Security Groups** - Egress-only by default (optional dashboard access via IP whitelist)
- **SSM Parameter Store** - Secure secrets management (see `docs/secrets.md`)

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
│   ├── storage/                # EFS persistent storage
│   ├── iam/                    # Roles, policies, instance profiles
│   └── monitoring/             # CloudWatch alarms, SNS alerts
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

# Get the SSM connect command
terraform output ssm_connect_command
```

## Module Reference

| Module | Purpose |
|--------|---------|
| `bootstrap` | Creates S3 bucket for Terraform state with versioning and encryption |
| `compute` | EC2 on-demand instance with full container mode (persistent /home/node volume) |
| `networking` | Security groups (EC2, EFS), VPC Flow Logs to CloudWatch |
| `storage` | EFS file system with mount target and automatic backups |
| `iam` | IAM role, instance profile, policies for SSM, CloudWatch |
| `monitoring` | CloudWatch alarms (instance status, memory), SNS topic for alerts |

## Post-Deployment Setup

1. **Connect to the instance:**
   ```bash
   aws ssm start-session --target <instance-id> --region us-east-1 --profile admin
   ```

2. **Switch to ec2-user** (SSM starts as `ssm-user`, not `ec2-user`):
   ```bash
   sudo su - ec2-user
   ```

3. **Run OpenClaw setup:**
   ```bash
   cd /opt/openclaw/openclaw-docker
   ./docker-setup.sh
   ```

   > **Important:** Do NOT run the setup script with `sudo`. The script must run as `ec2-user` so Docker bind mounts have correct ownership for the container's `node` user.

4. **The setup script will:**
   - Build the Docker image
   - Run the onboarding wizard (interactive)
   - Generate a gateway token (saved to `.env`)
   - Start the gateway

5. **Access the Control UI:**
   - URL: `http://127.0.0.1:18789/`
   - Paste the token from `.env` into Settings

### Data Persistence

**EFS Storage:**
- Config directory: `/opt/openclaw/.openclaw` (OpenClaw config, skills, memories)
- Automatic backups via AWS Backup (EFS backup policy enabled)
- Docker container logs streamed to CloudWatch (`/openclaw/production/docker`)

**Docker Volume (Full Container Mode - Always Enabled):**
- Persistent `/home/node` directory inside container
- Includes: Homebrew, CLI tools (gog, gh), auth tokens, npm cache, Playwright browsers
- Survives container rebuilds and instance recreation

### Automatic Resume on Instance Restart

OpenClaw automatically resumes after instance restarts (reboots, spot replacement, or recreation) without manual intervention.

**How It Works:**

When an instance launches, the user_data script:
1. Mounts EFS with persistent config
2. Detects existing `.env` and `openclaw.json`
3. Automatically starts the gateway service
4. Typical resume time: 5-7 minutes

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

To stop auto-started service:
```bash
aws ssm start-session --target <instance-id> --region us-east-1 --profile admin
sudo su - ec2-user
cd /opt/openclaw/openclaw-docker
docker compose down
```

**Troubleshooting:**

If auto-resume fails:
1. Check logs in CloudWatch: `/openclaw/production/user-data`
2. Look for `InstanceResumeFailure` metric with reason dimension
3. Common issues:
   - Missing or corrupted `.env` file
   - Docker image missing (will auto-rebuild)
   - Port 18789 already in use
4. Manual recovery: SSH in and run `docker-setup.sh`

**First-Time Setup:**

Auto-resume only works after initial onboarding. For first deployment:
1. Follow standard setup instructions in "Post-Deployment Setup"
2. Complete onboarding via `docker-setup.sh`
3. After onboarding, all future instance restarts will auto-resume

### Remote Dashboard Access (Optional)

By default, the OpenClaw dashboard is only accessible via SSM Session Manager. To enable remote access from your IP:

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

### Full-Featured Container Mode (Always Enabled)

The infrastructure now runs in full-featured container mode by default, which provides:

**Persistent Storage:**
- Docker named volume (`openclaw_home`) automatically created for `/home/node`
- Homebrew installations persist across container rebuilds
- CLI tools (gog, gh, etc.) persist across instance recreation
- Authentication tokens persist in `/home/node/.config/`
- npm cache and Playwright browsers persist

**Automatic Setup:**
- `docker-compose.override.yml` automatically created on instance boot
- Playwright browsers auto-install on instance restart (configurable)
- `install-playwright.sh` script created for manual browser installation

**Customization:**
```hcl
# Custom volume name (in terraform.tfvars)
openclaw_home_volume = "my_custom_volume"

# Custom APT packages (default includes Playwright deps)
openclaw_docker_apt_packages = "libnss3 libnspr4 ..."

# Disable auto-install of browsers on resume
install_playwright_browsers = false
```

**Manual Playwright Installation:**
After completing `docker-setup.sh`, you can manually install browsers:
```bash
./install-playwright.sh
```

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
| `dashboard_allowed_ip` | `""` | IP address (CIDR) for dashboard access (port 18789) |
| `openclaw_home_volume` | `openclaw_home` | Docker volume name for /home/node (always enabled) |
| `openclaw_docker_apt_packages` | `<playwright deps>` | APT packages for Playwright support (always installed) |
| `install_playwright_browsers` | `true` | Auto-install Playwright browsers on resume |
