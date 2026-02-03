# Full-Featured Container Mode

This guide covers the optional full-featured container support for OpenClaw, which enables:

- Persistent `/home/node` directory via Docker named volume
- Playwright browser automation with pre-installed system dependencies
- Automatic browser installation on instance restart

## Quick Start

1. **Enable in `terraform.tfvars`:**
   ```hcl
   enable_full_container = true
   ```

2. **Apply:**
   ```bash
   cd environments/production
   terraform apply
   ```

3. **Complete initial setup** (first deployment only):
   ```bash
   aws ssm start-session --target <instance-id> --region us-east-1 --profile admin
   sudo su - ec2-user
   cd /opt/openclaw/openclaw-docker
   ./docker-setup.sh
   ```

4. **Install Playwright browsers** (after onboarding):
   ```bash
   ./install-playwright.sh
   ```

## How It Works

### Docker Named Volume

When `enable_full_container = true`, a `docker-compose.override.yml` file is created that:

- Mounts a Docker named volume to `/home/node` inside the container
- Persists npm cache, Playwright browsers, and user data
- Survives container rebuilds and upstream `git pull` updates

```yaml
# Auto-generated docker-compose.override.yml
services:
  openclaw-gateway:
    environment:
      - PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright
    volumes:
      - openclaw_home:/home/node

volumes:
  openclaw_home:
    name: openclaw_home
```

### Playwright System Dependencies

The default `openclaw_docker_apt_packages` variable includes all system libraries required by Playwright:

```
libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2
libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2
libgbm1 libasound2
```

These are exported as environment variables for use by custom Dockerfile builds.

### Browser Auto-Installation

On instance restart (auto-resume):

1. The user_data script detects existing configuration
2. Creates/updates `docker-compose.override.yml`
3. Starts the gateway container
4. Checks if Playwright browsers exist in the volume
5. If missing, runs `npx playwright install chromium`

CloudWatch metrics track installation status:
- `PlaywrightInstallSuccess` - Browsers installed successfully
- `PlaywrightInstallFailure` - Installation failed (non-fatal)

### First-Time Setup

Browser auto-installation only works after initial onboarding. For new deployments:

1. The `install-playwright.sh` helper script is created automatically
2. After `docker-setup.sh` completes onboarding, run `./install-playwright.sh`
3. Future spot replacements will auto-install browsers

## Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_full_container` | `false` | Master switch for full container features |
| `openclaw_home_volume` | `openclaw_home` | Docker volume name for `/home/node` |
| `openclaw_docker_apt_packages` | `<playwright deps>` | Space-separated APT packages |
| `install_playwright_browsers` | `true` | Auto-install browsers on resume |

### Customization Examples

**Custom volume name:**
```hcl
openclaw_home_volume = "my_openclaw_data"
```

**Disable auto-install (manual control):**
```hcl
install_playwright_browsers = false
```

**Additional APT packages:**
```hcl
openclaw_docker_apt_packages = "libnss3 libnspr4 ... my-extra-package"
```

## Troubleshooting

### Playwright browsers not working

1. **Check if browsers are installed:**
   ```bash
   docker compose exec openclaw-gateway ls /home/node/.cache/ms-playwright/
   ```

2. **Manually install browsers:**
   ```bash
   docker compose exec openclaw-gateway npx playwright install chromium
   ```

3. **Check system dependencies:**
   ```bash
   docker compose exec openclaw-gateway npx playwright install-deps chromium
   ```

### Volume not persisting

1. **Verify override file exists:**
   ```bash
   cat /opt/openclaw/openclaw-docker/docker-compose.override.yml
   ```

2. **Check Docker volumes:**
   ```bash
   docker volume ls | grep openclaw
   ```

3. **Inspect volume:**
   ```bash
   docker volume inspect openclaw_home
   ```

### Auto-resume not installing browsers

1. **Check CloudWatch logs:**
   ```bash
   aws logs tail /openclaw/production/user-data --follow --profile admin
   ```

2. **Check metrics:**
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace "OpenClaw" \
     --metric-name "PlaywrightInstallFailure" \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Sum \
     --region us-east-1 \
     --profile admin
   ```

3. **Verify feature is enabled:**
   ```bash
   terraform output -json | jq '.setup_instructions.value'
   ```
   Look for "Full Container Mode" in the output.

### Reverting to standard mode

1. **Disable in terraform.tfvars:**
   ```hcl
   enable_full_container = false
   ```

2. **Apply:**
   ```bash
   terraform apply
   ```

3. **Remove override file (optional):**
   ```bash
   rm /opt/openclaw/openclaw-docker/docker-compose.override.yml
   docker compose down
   docker compose up -d openclaw-gateway
   ```

4. **Remove volume (optional, deletes data):**
   ```bash
   docker volume rm openclaw_home
   ```

## Architecture Notes

### Why docker-compose.override.yml?

Using an override file instead of modifying the main `docker-compose.yml`:

- Survives `git pull` of upstream OpenClaw repository
- Follows Docker Compose best practices for local customization
- Easy to inspect and debug
- Can be manually edited for additional customizations

### Why auto-install browsers on resume?

Instances can be terminated and replaced at any time (spot interruptions, maintenance, or manual recreation). Without auto-install:

- Users would need to manually SSH in after each instance restart
- Browser automation would silently fail until manual intervention
- Defeats the purpose of "set it and forget it" infrastructure

The auto-install adds ~2-3 minutes to resume time but ensures the instance is fully functional automatically.

**Note:** With on-demand instances (the default), browsers are typically only installed once since the instance is not subject to spot interruptions. The auto-install primarily benefits spot instance users or when instances are manually recreated.

### Resource Impact

- **Docker volume:** ~500MB for Chromium browser
- **RAM usage:** Playwright browsers use ~200-500MB when running
- **CPU:** Browser installation takes 2-3 minutes on t3.medium
- **User data size:** Feature adds ~3KB to user_data script (well within 16KB limit)
