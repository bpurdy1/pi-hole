# Cloudflare Tunnel Setup with GL.iNet Flint 2

Securely expose your Pi-hole admin GUI (and other services) to the internet without opening any ports on your router.

## What is a Cloudflare Tunnel?

A Cloudflare Tunnel creates an outbound-only encrypted connection from your network to Cloudflare's edge. No inbound ports need to be opened on your router.

```
Internet → Cloudflare Edge → Encrypted Tunnel → cloudflared (Pi) → Pi-hole
```

Benefits:
- No port forwarding required
- Free HTTPS certificates
- Zero Trust access controls (email OTP, identity providers)
- DDoS protection
- No dynamic DNS needed

## Prerequisites

- A **domain name** you own (any registrar)
- A **Cloudflare account** (free tier works)
- Your Pi-hole + Unbound Docker stack already running on Raspberry Pi

## Step 1: Setup Cloudflare Account

1. Sign up at [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
2. Add your domain to Cloudflare
3. Update your domain registrar's nameservers to the ones Cloudflare provides
4. Wait for propagation (usually under an hour)

## Step 2: Create a Tunnel

1. In the Cloudflare dashboard sidebar, click **Zero Trust** (or go to [https://one.dash.cloudflare.com](https://one.dash.cloudflare.com))
2. Select the **Free** plan
3. Navigate to **Networks → Connectors → Cloudflare Tunnels**
4. Click **Create a tunnel**
5. Select **Cloudflared** as connector type → **Next**
6. Enter a tunnel name (e.g., `home-pi`) → **Save tunnel**
7. **Copy the tunnel token** — you'll need this next
8. Don't close this page yet

## Step 3: Add Tunnel Token to .env

On your Pi, add the token to your `.env` file:

```bash
cd ~/pihole
vim .env
```

Add this line:
```
TUNNEL_TOKEN=eyJhIjoiNGY4...your_long_token_here
```

## Step 4: Add cloudflared to Docker Compose

Add the `cloudflared` service to your `docker-compose.yml`:

```yaml
  cloudflared:
    container_name: cloudflared
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${TUNNEL_TOKEN}
    networks:
      pihole-net:
    depends_on:
      - pihole
```

Place it after the `pihole` service block, before the `networks` section.

## Step 5: Deploy

```bash
cd ~/pihole
sudo docker compose up -d
```

Verify all three containers are running:
```bash
sudo docker compose ps
```

You should see `pihole`, `unbound`, and `cloudflared` all running.

## Step 6: Configure Public Hostname

Back in the Cloudflare Zero Trust dashboard (your tunnel should now show as connected):

1. Go to your tunnel → **Public Hostnames** tab
2. Click **Add a public hostname**
3. Fill in:
   - **Subdomain:** `pihole`
   - **Domain:** Select your domain
   - **Type:** `HTTP`
   - **URL:** `pihole:80`
4. Click **Save hostname**

Your Pi-hole is now accessible at: `https://pihole.yourdomain.com/admin`

> **Note:** Use `pihole:80` (not `localhost:8080`) because `cloudflared` is on the same Docker network and can reach the Pi-hole container directly by name.

## Step 7: Secure with Cloudflare Access (Important)

Without this, anyone who knows your hostname can reach your Pi-hole login page.

### 7.1 Add One-Time PIN Identity Provider

1. In Zero Trust dashboard → **Integrations → Identity Providers**
2. Click **Add new identity provider**
3. Select **One-time PIN**
4. Save

### 7.2 Create Access Application

1. Go to **Access → Applications**
2. Click **Add an application** → **Self-hosted**
3. Configure:
   - **Application name:** `Pi-hole Admin`
   - **Session duration:** `24 hours`
   - **Application domain:** `pihole.yourdomain.com`
4. Add an **Access Policy:**
   - **Policy name:** `Allow me`
   - **Action:** `Allow`
   - **Include rule:** Emails — enter your email address
5. Save

Now when you visit `pihole.yourdomain.com`, Cloudflare prompts for your email, sends a one-time PIN, and only grants access if the email matches your policy.

## Network Diagram

```
Remote Access:
  Phone/Laptop → Internet → Cloudflare Edge → Tunnel → cloudflared → Pi-hole GUI
                                                          (Docker)

Local DNS (unchanged):
  Devices → Pi-hole → Unbound → Root DNS → Internet
```

The tunnel only handles web traffic to your public hostnames. Your DNS resolution path is completely unaffected.

## Exposing Additional Services

Add more public hostnames in the Cloudflare dashboard:

| Subdomain | Domain | Type | URL |
|-----------|--------|------|-----|
| `pihole` | `yourdomain.com` | `HTTP` | `pihole:80` |
| `grafana` | `yourdomain.com` | `HTTP` | `grafana:3000` |
| `home` | `yourdomain.com` | `HTTP` | `192.168.8.50:8123` |

For services in the same Docker network, use the container name and internal port.
For services outside Docker, use the LAN IP and port.

## Security Checklist

- [ ] `TUNNEL_TOKEN` is in `.env` (not hardcoded in docker-compose.yml)
- [ ] `.env` is in `.gitignore` (already configured)
- [ ] Cloudflare Access policy is configured with email allowlist
- [ ] Pi-hole admin has a strong password (`FTLCONF_webserver_api_password`)
- [ ] Only expose services you actually need remotely
- [ ] Do NOT use `network_mode: host` for cloudflared
- [ ] Regularly update cloudflared: `sudo docker compose pull cloudflared && sudo docker compose up -d cloudflared`

## Troubleshooting

### Tunnel Not Connecting
```bash
# Check cloudflared logs
sudo docker logs cloudflared --tail 50

# Verify token is set
sudo docker exec cloudflared printenv TUNNEL_TOKEN
```

### Can't Reach Pi-hole Through Tunnel
```bash
# Test from inside cloudflared container
sudo docker exec cloudflared wget -qO- http://pihole:80/admin/ | head -5

# Make sure containers are on same network
sudo docker network inspect pihole-net
```

### Update cloudflared
```bash
cd ~/pihole
sudo docker compose pull cloudflared
sudo docker compose up -d cloudflared
```
