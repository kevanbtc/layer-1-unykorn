#!/bin/bash
# Sentry node initialization script
# This script runs on first boot of EC2 sentry instances

set -e

SENTRY_INDEX=${sentry_index}
CHAIN_ID=${chain_id}
ENVIRONMENT=${environment}

echo "=== Initializing Unykorn L1 Sentry Node $SENTRY_INDEX ==="

# Update system packages
apt-get update
apt-get upgrade -y
apt-get install -y \
    docker.io \
    docker-compose \
    fail2ban \
    ufw \
    nginx \
    certbot \
    python3-certbot-nginx \
    jq \
    htop \
    net-tools \
    awscli

# Enable Docker service
systemctl enable docker
systemctl start docker

# Configure firewall (allow public RPC but rate limit)
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 30303/tcp  # P2P
ufw allow 30303/udp  # P2P discovery
ufw allow 80/tcp     # HTTP (for Let's Encrypt)
ufw allow 443/tcp    # HTTPS
ufw limit 8545/tcp   # RPC (rate limited)
ufw --force enable

# Create data directories
mkdir -p /data/sentry-$SENTRY_INDEX
mkdir -p /genesis
mkdir -p /config
mkdir -p /var/www/html

# Install CloudWatch agent
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
            "log_group_name": "/unykorn/sentries",
            "log_stream_name": "sentry-$SENTRY_INDEX-{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/unykorn/sentries",
            "log_stream_name": "nginx-access-$SENTRY_INDEX"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json \
    -s

# Configure Docker
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

# Create systemd service for Besu sentry
cat > /etc/systemd/system/besu-sentry.service <<EOF
[Unit]
Description=Hyperledger Besu Sentry Node $SENTRY_INDEX
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=10s
User=root
WorkingDirectory=/data/sentry-$SENTRY_INDEX

ExecStartPre=-/usr/bin/docker stop besu-sentry-$SENTRY_INDEX
ExecStartPre=-/usr/bin/docker rm besu-sentry-$SENTRY_INDEX

ExecStart=/usr/bin/docker run --name besu-sentry-$SENTRY_INDEX \\
  --network=host \\
  -v /data/sentry-$SENTRY_INDEX:/data \\
  -v /genesis:/genesis \\
  -v /config:/config \\
  hyperledger/besu:24.1.0 \\
  --data-path=/data \\
  --genesis-file=/genesis/genesis.json \\
  --rpc-http-enabled=true \\
  --rpc-http-host=0.0.0.0 \\
  --rpc-http-port=8545 \\
  --rpc-http-api=ETH,NET,WEB3,TXPOOL \\
  --rpc-http-cors-origins="*" \\
  --host-allowlist="*" \\
  --rpc-ws-enabled=true \\
  --rpc-ws-host=0.0.0.0 \\
  --rpc-ws-port=8546 \\
  --rpc-ws-api=ETH,NET,WEB3 \\
  --p2p-host=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) \\
  --p2p-port=30303 \\
  --min-gas-price=1000000000 \\
  --metrics-enabled=true \\
  --metrics-host=0.0.0.0 \\
  --metrics-port=9545 \\
  --tx-pool-max-size=4096

ExecStop=/usr/bin/docker stop besu-sentry-$SENTRY_INDEX

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable besu-sentry.service

# Configure Nginx as reverse proxy with rate limiting
cat > /etc/nginx/sites-available/default <<'NGINXEOF'
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=rpc_limit:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=ws_limit:10m rate=5r/s;

# Upstream Besu RPC
upstream besu_rpc {
    server 127.0.0.1:8545;
    keepalive 32;
}

# Upstream Besu WebSocket
upstream besu_ws {
    server 127.0.0.1:8546;
    keepalive 32;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;
    
    # Health check endpoint (no rate limit)
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    
    # RPC endpoint (rate limited)
    location / {
        limit_req zone=rpc_limit burst=20 nodelay;
        
        proxy_pass http://besu_rpc;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type";
    }
    
    # WebSocket endpoint (rate limited)
    location /ws {
        limit_req zone=ws_limit burst=10 nodelay;
        
        proxy_pass http://besu_ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # WebSocket timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
NGINXEOF

# Enable Nginx
systemctl enable nginx
systemctl restart nginx

# System tuning
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

cat >> /etc/security/limits.conf <<EOF
*    soft    nofile    1048576
*    hard    nofile    1048576
root soft    nofile    1048576
root hard    nofile    1048576
EOF

cat >> /etc/sysctl.conf <<EOF
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.netdev_max_backlog = 250000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
fs.file-max = 2097152
vm.swappiness = 1
EOF

sysctl -p

# Create status script
cat > /usr/local/bin/sentry-status.sh <<'EOF'
#!/bin/bash
echo "=== Sentry Node Status ==="
echo "Docker Status:"
docker ps

echo -e "\nBlock Number:"
curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq .

echo -e "\nPeer Count:"
curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' | jq .

echo -e "\nNginx Status:"
systemctl status nginx --no-pager | head -n 5

echo -e "\nRecent RPC Requests:"
tail -n 10 /var/log/nginx/access.log
EOF

chmod +x /usr/local/bin/sentry-status.sh

cat > /root/README.txt <<EOF
=====================================
UNYKORN L1 SENTRY NODE $SENTRY_INDEX
=====================================

This instance is a public-facing RPC node for Unykorn L1 (Chain ID: $CHAIN_ID).

ROLE:
- Provide public JSON-RPC access
- Shield validators from public traffic
- No validator keys (safe to expose publicly)

TO START THE SENTRY:
1. Upload genesis.json to /genesis/
2. Run: systemctl start besu-sentry.service

CHECK STATUS:
- Service: systemctl status besu-sentry.service
- Quick status: /usr/local/bin/sentry-status.sh
- Test RPC: curl -X POST http://localhost:8545 -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

NGINX PROXY:
- HTTP: Port 80 (redirects to HTTPS if configured)
- HTTPS: Port 443 (configure SSL with certbot)
- Rate limit: 10 req/s per IP (burst 20)
- WebSocket: /ws endpoint

SSL SETUP (after DNS configured):
sudo certbot --nginx -d rpc.unykorn.com

MONITORING:
- Metrics: http://localhost:9545/metrics
- Access logs: /var/log/nginx/access.log

SCALING:
- Horizontal: Add more sentry instances
- Vertical: Increase instance size for more throughput

This instance was initialized on: $(date)
Environment: $ENVIRONMENT
=====================================
EOF

echo "=== Sentry Node $SENTRY_INDEX initialization complete ==="
