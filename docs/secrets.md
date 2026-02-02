# SSM Parameter Store for Secrets

This Terraform configuration grants the EC2 instance access to AWS Systems Manager Parameter Store for secure secret management. Use this instead of hardcoding secrets in environment variables or config files.

## Storing Secrets

Store secrets in Parameter Store with the path prefix `/openclaw/{environment}/`:

```bash
# Store a secret (SecureString encrypts with KMS)
aws ssm put-parameter \
  --name "/openclaw/production/discord-token" \
  --value "your-discord-bot-token" \
  --type "SecureString" \
  --region us-east-1

# Store another secret
aws ssm put-parameter \
  --name "/openclaw/production/api-key" \
  --value "your-api-key" \
  --type "SecureString" \
  --region us-east-1
```

## Retrieving Secrets on EC2

From the EC2 instance, retrieve secrets using the AWS CLI:

```bash
# Get a single secret
aws ssm get-parameter \
  --name "/openclaw/production/discord-token" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region us-east-1

# Get all secrets with a prefix
aws ssm get-parameters-by-path \
  --path "/openclaw/production/" \
  --with-decryption \
  --region us-east-1
```

## Using Secrets in Applications

### Shell Script Example

```bash
#!/bin/bash
export DISCORD_TOKEN=$(aws ssm get-parameter \
  --name "/openclaw/production/discord-token" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region us-east-1)

# Run your application with the secret
openclaw start
```

### Node.js Example

```javascript
const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");

const client = new SSMClient({ region: "us-east-1" });

async function getSecret(name) {
  const command = new GetParameterCommand({
    Name: name,
    WithDecryption: true,
  });
  const response = await client.send(command);
  return response.Parameter.Value;
}

// Usage
const discordToken = await getSecret("/openclaw/production/discord-token");
```

## IAM Permissions

The EC2 instance role has permissions to:

- `ssm:GetParameter` - Read individual parameters
- `ssm:GetParameters` - Read multiple parameters
- `ssm:GetParametersByPath` - List and read parameters by path prefix

These permissions are scoped to parameters matching `arn:aws:ssm:*:*:parameter/openclaw/*`.

## Security Notes

- Always use `SecureString` type for sensitive values (encrypts with AWS KMS)
- Parameter Store integrates with CloudTrail for audit logging
- Secrets are never stored in Terraform state
- Rotate secrets regularly by updating the parameter value
