# OpenClaw Terraform Infrastructure

Terraform modules for hosting [OpenClaw](https://github.com/openclaw/openclaw) on AWS. Deploys a single EC2 instance (Ubuntu 24.04) with OpenClaw installed directly via npm, persistent EFS storage, CloudWatch monitoring, and SSH access.

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

## Features

- **SSH access** -- Terraform-managed key pair, restricted by CIDR
- **SSM fallback** -- AWS Session Manager for keyless access
- **Persistent storage** -- EFS for config and workspace
- **Auto-resume** -- OpenClaw gateway restarts automatically after instance reboots
- **Monitoring** -- CloudWatch alarms for instance status and memory, SNS alerts
- **VPC Flow Logs** -- network traffic monitoring
- **Secrets via SSM Parameter Store** -- no secrets in code (see [`docs/secrets.md`](docs/secrets.md))

## Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.10
- [AWS CLI](https://aws.amazon.com/cli/) v2
- An AWS account with an SSO profile configured

```bash
aws configure sso --profile admin
aws sts get-caller-identity --profile admin
```

## Quick Start

```bash
cd environments/production

# 1. Configure backend with your AWS account ID
cp backend.tfbackend.example backend.tfbackend
# Edit backend.tfbackend -- replace YOUR_ACCOUNT_ID with your AWS account ID

# 2. Bootstrap the state bucket (first time only)
cd ../../modules/bootstrap
terraform init && terraform apply
cd ../../environments/production

# 3. Initialize and deploy
terraform init -backend-config=backend.tfbackend
terraform plan
terraform apply

# 4. Connect to the instance
ssh -i <your-private-key> ubuntu@$(terraform output -raw instance_public_ip)
```

## Post-Deployment Setup

Once connected via SSH:

```bash
openclaw-setup
```

The setup helper runs `openclaw onboard` (interactive wizard) and starts the gateway via systemd. After initial setup, the gateway auto-resumes on every instance restart.

See [AGENTS.md](AGENTS.md) for full documentation on data persistence, auto-resume, remote dashboard access, and troubleshooting.

## Modules

| Module | Purpose |
|--------|---------|
| `bootstrap` | S3 bucket for Terraform state (versioning + encryption) |
| `compute` | EC2 instance with Ubuntu 24.04, Node.js 22, OpenClaw via npm |
| `networking` | Security groups (EC2, EFS), VPC Flow Logs |
| `storage` | EFS file system with mount target and automatic backups |
| `iam` | IAM role, instance profile, SSM + CloudWatch policies |
| `monitoring` | CloudWatch alarms, SNS alert topic |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region |
| `instance_type` | `t3.medium` | EC2 instance size |
| `root_volume_size` | `20` | Root EBS volume in GB |
| `environment` | `production` | Environment tag |
| `project_name` | `openclaw` | Resource naming prefix |
| `alert_email` | `""` | CloudWatch alert email |
| `public_key` | `""` | SSH public key content |
| `ssh_allowed_cidr` | `""` | CIDR for SSH access (port 22) |
| `dashboard_allowed_ip` | `""` | IP CIDR for remote dashboard access |
| `install_playwright_browsers` | `true` | Auto-install Playwright browsers on resume |

See [`environments/production/terraform.tfvars.example`](environments/production/terraform.tfvars.example) for a full example.

## Contributing

Contributions are welcome! Here's how to get started:

1. **Fork the repo** and create a feature branch from `main`.

2. **Follow the Terraform conventions:**
   - Run `terraform fmt -recursive` before committing
   - Run `terraform validate` in `environments/production/`
   - All resources must have `environment` and `project_name` tags
   - Keep modules focused on a single responsibility

3. **Structure your changes:**
   - Module changes go in `modules/<module>/`
   - Environment wiring goes in `environments/production/`
   - Sensitive values must use SSM Parameter Store -- never hardcode secrets

4. **Test your changes:**
   ```bash
   cd environments/production
   terraform fmt -check -recursive ../..
   terraform validate
   terraform plan
   ```

5. **Open a pull request** against `main` with a clear description of what changed and why.

### Guidelines

- Keep PRs focused -- one logical change per PR
- Add or update variable descriptions and validation blocks when adding new inputs
- Don't modify the `bootstrap` module after initial setup (it manages the state bucket)
- Use explicit resource references over `depends_on` when possible

## License

This project is open source. See the upstream [OpenClaw](https://github.com/openclaw/openclaw) project for license details.
