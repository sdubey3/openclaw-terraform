#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script at $(date)"

# Update system packages
dnf update -y

# Install Docker and EFS utilities
dnf install -y docker amazon-efs-utils aws-cli
systemctl enable docker
systemctl start docker

# Create mount point
mkdir -p ${mount_point}

# Mount EFS with TLS
echo "Mounting EFS filesystem ${efs_id}..."
mount -t efs -o tls ${efs_id}:/ ${mount_point}

# Add to fstab for persistence across reboots
echo "${efs_id}:/ ${mount_point} efs _netdev,tls 0 0" >> /etc/fstab

# Create data directories
mkdir -p ${mount_point}/data
mkdir -p ${mount_point}/logs

# Set permissions
chown -R 1000:1000 ${mount_point}

# Create backup script
cat > /usr/local/bin/openclaw-backup.sh << 'BACKUP_SCRIPT'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/tmp/openclaw-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
cp -r ${mount_point}/data "$BACKUP_DIR/"
tar -czf "/tmp/openclaw-backup-$TIMESTAMP.tar.gz" -C "$BACKUP_DIR" .
aws s3 cp "/tmp/openclaw-backup-$TIMESTAMP.tar.gz" "s3://${s3_bucket}/backups/"
rm -rf "$BACKUP_DIR" "/tmp/openclaw-backup-$TIMESTAMP.tar.gz"
echo "Backup completed: $TIMESTAMP"
BACKUP_SCRIPT
chmod +x /usr/local/bin/openclaw-backup.sh

# Setup daily backup cron job
echo "0 3 * * * root /usr/local/bin/openclaw-backup.sh >> /var/log/openclaw-backup.log 2>&1" > /etc/cron.d/openclaw-backup

echo "OpenClaw infrastructure setup complete at $(date)"
echo "Connect via: aws ssm start-session --target <instance-id>"
