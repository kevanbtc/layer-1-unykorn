#!/bin/bash
# Validator node initialization script
# This script runs on first boot of EC2 validator instances

set -e

VALIDATOR_INDEX=${validator_index}
CHAIN_ID=${chain_id}
ENVIRONMENT=${environment}

echo "=== Initializing Unykorn L1 Validator $VALIDATOR_INDEX ==="

# Update system packages
apt-get update
apt-get upgrade -y
apt-get install -y \
    docker.io \
    docker-compose \
    fail2ban \
    ufw \
    jq \
    htop \
    net-tools \
    awscli

# Enable Docker service
systemctl enable docker
systemctl start docker

# Configure firewall (deny all, allow only from private subnet)
ufw default deny incoming
ufw default allow outgoing
ufw allow from 10.0.0.0/16  # VPC CIDR
ufw --force enable

# Create data directories
mkdir -p /data/validator-$VALIDATOR_INDEX
mkdir -p /genesis
mkdir -p /secrets
mkdir -p /config

# Set proper permissions
chmod 700 /data/validator-$VALIDATOR_INDEX
chmod 700 /secrets

# Install CloudWatch agent for logging
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "/unykorn/validators",
            "log_stream_name": "validator-$VALIDATOR_INDEX-{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "Unykorn/Validators",
    "metrics_collected": {
      "disk": {
        "measurement": [
          {"name": "used_percent", "rename": "DiskUsedPercent"}
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "rename": "MemoryUsedPercent"}
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json \
    -s

# Configure Docker daemon for production
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF

systemctl restart docker

# Create systemd service for Besu validator
cat > /etc/systemd/system/besu-validator.service <<EOF
[Unit]
Description=Hyperledger Besu Validator Node $VALIDATOR_INDEX
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=10s
User=root
WorkingDirectory=/data/validator-$VALIDATOR_INDEX

ExecStartPre=-/usr/bin/docker stop besu-validator-$VALIDATOR_INDEX
ExecStartPre=-/usr/bin/docker rm besu-validator-$VALIDATOR_INDEX

ExecStart=/usr/bin/docker run --name besu-validator-$VALIDATOR_INDEX \\
  --network=host \\
  -v /data/validator-$VALIDATOR_INDEX:/data \\
  -v /genesis:/genesis \\
  -v /secrets:/secrets \\
  -v /config:/config \\
  hyperledger/besu:24.1.0 \\
  --data-path=/data \\
  --genesis-file=/genesis/genesis.json \\
  --rpc-http-enabled=false \\
  --rpc-http-api=ETH,NET,WEB3 \\
  --host-allowlist="*" \\
  --engine-rpc-enabled=true \\
  --engine-rpc-port=8551 \\
  --engine-host-allowlist="*" \\
  --engine-jwt-secret=/secrets/jwt-secret.hex \\
  --p2p-host=\$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) \\
  --p2p-port=30303 \\
  --min-gas-price=1000000000 \\
  --metrics-enabled=true \\
  --metrics-host=0.0.0.0 \\
  --metrics-port=9545

ExecStop=/usr/bin/docker stop besu-validator-$VALIDATOR_INDEX

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (but don't start yet - wait for keys to be uploaded)
systemctl daemon-reload
systemctl enable besu-validator.service

# Create status check script
cat > /usr/local/bin/validator-status.sh <<'EOF'
#!/bin/bash
echo "=== Validator Status ==="
echo "Docker Status:"
docker ps

echo -e "\nPeer Count:"
docker exec besu-validator-$VALIDATOR_INDEX curl -s http://localhost:9545/metrics | grep besu_peers_connected_total || echo "Metrics not available"

echo -e "\nBlock Number:"
docker logs besu-validator-$VALIDATOR_INDEX 2>&1 | tail -n 20 | grep "Imported new chain segment" | tail -n 1 || echo "No recent blocks"

echo -e "\nDisk Usage:"
df -h | grep -E "Filesystem|/data"

echo -e "\nMemory Usage:"
free -h
EOF

chmod +x /usr/local/bin/validator-status.sh

# Disable swap (recommended for blockchain nodes)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Set system limits for high performance
cat >> /etc/security/limits.conf <<EOF
*    soft    nofile    1048576
*    hard    nofile    1048576
root soft    nofile    1048576
root hard    nofile    1048576
EOF

# Kernel tuning for network performance
cat >> /etc/sysctl.conf <<EOF
# Network performance tuning
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.netdev_max_backlog = 250000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1

# File system tuning
fs.file-max = 2097152
vm.swappiness = 1
EOF

sysctl -p

# Create README for operators
cat > /root/README.txt <<EOF
=====================================
UNYKORN L1 VALIDATOR NODE $VALIDATOR_INDEX
=====================================

This instance is a production validator node for Unykorn L1 (Chain ID: $CHAIN_ID).

CRITICAL SECURITY NOTES:
- This node contains validator keys. Keep this instance HIGHLY SECURE.
- Never expose this instance to the public internet.
- Validator keys are in: /data/validator-$VALIDATOR_INDEX/key
- JWT secret is in: /secrets/jwt-secret.hex

TO START THE VALIDATOR:
1. Upload validator keys to /data/validator-$VALIDATOR_INDEX/
2. Upload genesis.json to /genesis/
3. Upload jwt-secret.hex to /secrets/
4. Run: systemctl start besu-validator.service

CHECK STATUS:
- Service: systemctl status besu-validator.service
- Logs: journalctl -u besu-validator.service -f
- Quick status: /usr/local/bin/validator-status.sh

MONITORING:
- Metrics endpoint: http://localhost:9545/metrics
- Prometheus scrapes this endpoint

EMERGENCY CONTACTS:
- DevOps Lead: [ADD CONTACT]
- Security Lead: [ADD CONTACT]

BACKUP PROCEDURE:
- Daily snapshots of EBS volumes are automated
- Manual backup: tar -czf /root/validator-backup.tar.gz /data /secrets

UPDATES:
- Update Besu image: Edit /etc/systemd/system/besu-validator.service
- Coordinate updates with other validators!

This instance was initialized on: $(date)
Environment: $ENVIRONMENT
=====================================
EOF

echo "=== Validator $VALIDATOR_INDEX initialization complete ==="
echo "Next steps:"
echo "1. Upload validator keys to /data/validator-$VALIDATOR_INDEX/"
echo "2. Upload genesis.json to /genesis/"
echo "3. Upload jwt-secret.hex to /secrets/"
echo "4. Start service: systemctl start besu-validator.service"
