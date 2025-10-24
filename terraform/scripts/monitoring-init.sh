#!/bin/bash
# Monitoring instance initialization script

set -e

ENVIRONMENT=${environment}

echo "=== Initializing Unykorn L1 Monitoring Stack ==="

apt-get update
apt-get upgrade -y
apt-get install -y \
    docker.io \
    docker-compose \
    ufw \
    nginx \
    jq \
    htop \
    awscli

systemctl enable docker
systemctl start docker

# Firewall (restrict Grafana access)
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 10.0.0.0/16 to any port 9090  # Prometheus (internal only)
ufw --force enable

mkdir -p /monitoring/{prometheus,grafana,alertmanager}
mkdir -p /config

# Docker daemon config
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker

echo "=== Monitoring stack initialization complete ==="
echo "Deploy monitoring stack via docker-compose"
