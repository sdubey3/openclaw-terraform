# Credential Persistence & Secret Management

## The Problem

OpenClaw runs in a Docker container. The workspace (`/home/node/.openclaw/workspace/`) is on EFS and survives everything. But `~/.config/` lives on a Docker named volume that can be wiped on container rebuilds, volume recreation, or EBS replacement.

Credentials stored in `~/.config/moltbook/`, `~/.config/twitter/`, etc. get lost.

## Solution: Two-Layer Persistence

### Layer 1: EFS Workspace Credentials (Symlinks)

Credentials are stored in the EFS-persistent workspace and symlinked to `~/.config/`:

```
/home/node/.openclaw/workspace/.credentials/   ← EFS (survives everything)
  ├── moltbook/credentials.json
  ├── moltipedia/credentials.json
  ├── moltslack/credentials.json
  ├── twilio/credentials.json
  ├── twitter/cookies.json
  └── github/app-key.pem

~/.config/moltbook → ../.openclaw/workspace/.credentials/moltbook  ← symlink
```

The `scripts/restore-credentials.sh` script recreates symlinks on every container start.

### Layer 2: AWS SSM Parameter Store (Encrypted Backup)

Secrets are also stored in SSM Parameter Store as encrypted `SecureString` parameters. On EC2 boot (before the container starts), the `user_data` script pulls all secrets from SSM and writes them to EFS.

This means credentials survive even EFS data loss (unlikely but possible).

## Storing Secrets

### From the EC2 host (recommended):

```bash
# Use the helper script
cd /opt/openclaw/.openclaw/workspace/scripts
./ssm-store.sh moltbook credentials '{"apiKey":"sk-abc","username":"clawdia_snaps"}'
./ssm-store.sh twitter cookies '{"ct0":"...","auth_token":"..."}'
./ssm-store.sh twilio credentials '{"accountSid":"AC...","authToken":"..."}'
```

This stores in both SSM (encrypted backup) and EFS (immediate access).

### Manually via AWS CLI:

```bash
aws ssm put-parameter \
  --name "/openclaw/production/moltbook/credentials" \
  --value '{"apiKey":"sk-abc","username":"clawdia_snaps"}' \
  --type "SecureString" \
  --overwrite \
  --region us-east-1
```

### From the container (write to EFS directly):

```bash
# Write credentials to workspace (persists on EFS)
mkdir -p /home/node/.openclaw/workspace/.credentials/moltbook
echo '{"apiKey":"sk-abc"}' > /home/node/.openclaw/workspace/.credentials/moltbook/credentials.json

# Run restore to create symlinks
bash /home/node/.openclaw/workspace/scripts/restore-credentials.sh
```

## Restoring Secrets

### Automatic (on every boot):

1. **EC2 user_data** pulls SSM parameters → writes to EFS `.credentials/`
2. **Container startup** (via BOOT.md hook) runs `restore-credentials.sh` → creates symlinks

### Manual:

```bash
# Inside the container
bash /home/node/.openclaw/workspace/scripts/restore-credentials.sh

# From EC2 host (re-pull from SSM)
cd /opt/openclaw/.openclaw/workspace/scripts
bash restore-credentials.sh
```

## SSM Parameter Naming

Parameters follow this convention:

```
/openclaw/{environment}/{service}/{key}

Examples:
  /openclaw/production/moltbook/credentials     → .credentials/moltbook/credentials.json
  /openclaw/production/twitter/cookies           → .credentials/twitter/cookies.json
  /openclaw/production/twilio/credentials        → .credentials/twilio/credentials.json
  /openclaw/production/github/app-key            → .credentials/github/app-key
```

## IAM Permissions

The EC2 instance role has:

- `ssm:GetParameter` — Read individual parameters
- `ssm:GetParameters` — Read multiple parameters
- `ssm:GetParametersByPath` — List and read all parameters under a prefix

Scoped to: `arn:aws:ssm:*:*:parameter/openclaw/*`

## Security Notes

- All SSM parameters use `SecureString` (encrypted with AWS KMS)
- EFS is encrypted at rest
- `.credentials/` files are chmod 600
- CloudTrail logs all SSM access
- Never commit credentials to git (`.credentials/` is in `.gitignore`)

## Files

| File | Location | Purpose |
|------|----------|---------|
| `restore-credentials.sh` | `scripts/` | Creates symlinks + pulls SSM secrets |
| `ssm-pull.js` | `scripts/` | Node.js SSM client (for in-container use) |
| `ssm-store.sh` | `scripts/` | Store credentials in SSM + EFS |
| `BOOT.md` | workspace root | Runs restore on gateway startup |

## Adding a New Service

1. Create the directory: `mkdir -p .credentials/myservice`
2. Write the credential file: `echo '...' > .credentials/myservice/credentials.json`
3. Run restore: `bash scripts/restore-credentials.sh`
4. (Optional) Back up to SSM: `./scripts/ssm-store.sh myservice credentials '...'`

The restore script auto-discovers all directories under `.credentials/` — no code changes needed.
