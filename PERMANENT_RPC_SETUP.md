# 🌐 PERMANENT PUBLIC RPC SETUP GUIDE
## Cloudflare Named Tunnel + Custom Domain Configuration

**Goal:** Replace temporary `*.trycloudflare.com` URLs with permanent `rpc.unykorn.org`

**Current Status:**
- ✅ Quick tunnel working: `https://admissions-producing-cut-elephant.trycloudflare.com`
- ⏳ Named tunnel setup: IN PROGRESS
- ⏳ Custom domain: PENDING (requires domain ownership)

---

## Option 1: Named Cloudflare Tunnel (Recommended)

### Prerequisites
- Cloudflare account (free tier works)
- Domain name (can use any: `unykorn.org`, `unykorn.io`, `unykorn.xyz`, etc.)
- cloudflared.exe already downloaded ✅

### Step 1: Login to Cloudflare

```powershell
.\cloudflared.exe login
```

This opens a browser window. Sign in to Cloudflare and authorize the tunnel.

### Step 2: Create Named Tunnel

```powershell
.\cloudflared.exe tunnel create unykorn-l1-rpc
```

**Output:**
```
Created tunnel unykorn-l1-rpc with id: <TUNNEL_ID>
Tunnel credentials written to: C:\Users\<USERNAME>\.cloudflared\<TUNNEL_ID>.json
```

**Save this Tunnel ID!** It's permanent.

### Step 3: Configure DNS

If you own `unykorn.org`:

```powershell
.\cloudflared.exe tunnel route dns unykorn-l1-rpc rpc.unykorn.org
```

This creates a CNAME record: `rpc.unykorn.org` → `<TUNNEL_ID>.cfargotunnel.com`

### Step 4: Create Tunnel Config File

Create: `C:\Users\Kevan\.cloudflared\config.yml`

```yaml
tunnel: <TUNNEL_ID>
credentials-file: C:\Users\Kevan\.cloudflared\<TUNNEL_ID>.json

ingress:
  - hostname: rpc.unykorn.org
    service: http://localhost:8555
  - service: http_status:404
```

### Step 5: Run Named Tunnel

```powershell
.\cloudflared.exe tunnel run unykorn-l1-rpc
```

**Result:** `https://rpc.unykorn.org` now routes to ChainID 7777 **permanently**!

Even if you restart the tunnel, the URL stays the same.

---

## Option 2: Production VPS with Custom Domain

### Prerequisites
- VPS (DigitalOcean, AWS, Linode, etc.)
- Ubuntu 22.04 LTS
- Domain with DNS access
- SSH access to VPS

### Infrastructure Stack
```
Internet → Cloudflare (DDoS protection) → nginx (TLS termination) → Besu (port 8545)
```

### Step 1: Deploy VPS

**Recommended Specs:**
- 2 vCPU
- 4GB RAM
- 50GB SSD
- Ubuntu 22.04
- Static IP address

### Step 2: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose -y

# Install nginx
sudo apt install nginx -y

# Install certbot (Let's Encrypt)
sudo apt install certbot python3-certbot-nginx -y
```

### Step 3: Deploy Besu

```bash
# Clone your repository or copy files
git clone <your-repo> /home/ubuntu/unykorn-l1
cd /home/ubuntu/unykorn-l1

# Copy validator key (CRITICAL - secure this!)
scp data/sovereign/key ubuntu@<VPS_IP>:/home/ubuntu/unykorn-l1/data/sovereign/

# Start Besu
docker-compose -f docker/docker-compose.sovereign.yml up -d
```

### Step 4: Configure nginx

Create `/etc/nginx/sites-available/rpc.unykorn.org`:

```nginx
upstream besu_rpc {
    server 127.0.0.1:8555;
    keepalive 32;
}

server {
    listen 80;
    server_name rpc.unykorn.org;

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name rpc.unykorn.org;

    # SSL certificates (managed by certbot)
    ssl_certificate /etc/letsencrypt/live/rpc.unykorn.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rpc.unykorn.org/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;

    # CORS headers (allow MetaMask)
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type" always;

    location / {
        if ($request_method = OPTIONS) {
            return 204;
        }

        proxy_pass http://besu_rpc;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/rpc.unykorn.org /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Step 5: Get SSL Certificate

```bash
sudo certbot --nginx -d rpc.unykorn.org
```

Follow prompts, select automatic redirect to HTTPS.

### Step 6: Update DNS

In your domain's DNS settings (e.g., Cloudflare, Namecheap):

```
Type: A
Name: rpc
Value: <VPS_IP_ADDRESS>
TTL: Auto or 300
```

**Wait 5-10 minutes for DNS propagation.**

### Step 7: Test Connection

```bash
curl -X POST https://rpc.unykorn.org \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

Expected: `{"jsonrpc":"2.0","id":1,"result":"0x1e61"}`

---

## Option 3: ngrok Pro (Quick Permanent URL)

If you don't have a domain but want a permanent URL:

### Step 1: Sign Up for ngrok

1. Go to https://ngrok.com
2. Create free account
3. Get authtoken from dashboard

### Step 2: Install & Configure

```powershell
# Download ngrok
Invoke-WebRequest -Uri "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip" -OutFile "ngrok.zip"
Expand-Archive ngrok.zip
.\ngrok\ngrok.exe config add-authtoken <YOUR_TOKEN>
```

### Step 3: Reserve Static Domain (Requires Paid Plan)

ngrok Pro ($8/month) gives you a permanent subdomain like:

```
https://unykorn-l1-rpc.ngrok.io
```

```powershell
.\ngrok\ngrok.exe http 8555 --domain=unykorn-l1-rpc.ngrok.io
```

This URL never changes, even across restarts.

---

## Comparison Table

| Method | Cost | Setup Time | Permanence | Custom Domain | DDoS Protection |
|--------|------|------------|------------|---------------|-----------------|
| **Quick Tunnel** | Free | 1 min | ❌ Changes | ❌ No | ✅ Yes (Cloudflare) |
| **Named Tunnel** | Free | 15 min | ✅ Permanent | ✅ Yes | ✅ Yes (Cloudflare) |
| **VPS + nginx** | $4-20/mo | 2-3 hours | ✅ Permanent | ✅ Yes | Optional (Cloudflare) |
| **ngrok Pro** | $8/mo | 5 min | ✅ Permanent | ⚠️ Subdomain only | ✅ Yes |

---

## Recommendation

**For immediate permanence (next 30 minutes):**
→ **Named Cloudflare Tunnel** (Option 1)

**Why:**
- Free forever
- 15-minute setup
- Permanent custom domain (`rpc.unykorn.org`)
- Automatic TLS certificates
- Cloudflare's global CDN + DDoS protection
- No VPS management overhead

**For production at scale (next 24-48 hours):**
→ **VPS + nginx** (Option 2)

**Why:**
- Full control over infrastructure
- Can run multiple validators on same VPS
- Add monitoring (Grafana/Prometheus)
- Custom rate limiting
- Direct validator→RPC connection (lower latency)

---

## Next Steps

**Choose your path and I'll execute the setup:**

1. **Named Tunnel** → Need Cloudflare account + domain name
2. **VPS Deployment** → Need VPS provider (DigitalOcean recommended)
3. **ngrok Pro** → Need ngrok account + $8/month

**Or we can run all three in parallel:**
- Named tunnel for public access (15 min)
- VPS for production (background deployment)
- Keep quick tunnel as backup until both are verified

**What's your preference?**
