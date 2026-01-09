# Pi-hole with Unbound on Raspberry Pi

Complete guide to set up Pi-hole with Unbound as a recursive DNS resolver on a Raspberry Pi.

## Overview

This setup includes:
- **Pi-hole**: DNS sinkhole for ad blocking
- **Unbound**: Recursive DNS resolver (no third-party DNS needed)

## Prerequisites

- Raspberry Pi (3B+, 4, or 5 recommended)
- MicroSD card (16GB minimum)
- Raspberry Pi OS installed (Lite or Desktop)
- Internet connection
- SSH access or keyboard/monitor

## Step 1: Prepare Your Raspberry Pi

### 1.1 Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### 1.2 Install Required Packages
```bash
sudo apt install -y git curl vim
```

### 1.3 Set a Static IP (Recommended)

Your Pi needs a consistent IP address so devices can always find it. There are two ways to do this:

#### Option A: DHCP Reservation (Recommended - Easier & Safer)

Let your router assign a fixed IP to your Pi. This is safer because:
- Pi stays on DHCP (no manual config to break)
- Router always gives the same IP based on MAC address

**Steps:**
1. Get your Pi's MAC address:
   ```bash
   ip link show wlan0 | grep ether   # For WiFi
   ip link show eth0 | grep ether    # For Ethernet
   ```

2. Log into your router admin panel (e.g., `http://192.168.8.1` for GL.iNet routers)

3. Find **DHCP Settings** or **LAN > Static IP Binding**

4. Add your Pi's MAC address and assign it a fixed IP (e.g., `192.168.8.100`)

#### Option B: Static IP on the Pi

Configure the Pi to use a static IP directly. **Warning:** If you use wrong settings, you may lose network access and need a monitor/keyboard to fix it.

First, check your current network info:
```bash
ip route                    # Shows gateway (router IP)
hostname -I                 # Shows current IP
nmcli con show              # Shows connection names
```

Then set a static IP (replace values with your network's settings):

**For Ethernet:**
```bash
sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.8.100/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.8.1
sudo nmcli con mod "Wired connection 1" ipv4.dns "1.1.1.1 1.0.0.1"
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo nmcli con up "Wired connection 1"
```

**For WiFi:**
```bash
sudo nmcli con mod "YOUR_WIFI_CONNECTION_NAME" ipv4.addresses 192.168.8.100/24
sudo nmcli con mod "YOUR_WIFI_CONNECTION_NAME" ipv4.gateway 192.168.8.1
sudo nmcli con mod "YOUR_WIFI_CONNECTION_NAME" ipv4.dns "1.1.1.1 1.0.0.1"
sudo nmcli con mod "YOUR_WIFI_CONNECTION_NAME" ipv4.method manual
sudo nmcli con up "YOUR_WIFI_CONNECTION_NAME"
```

**To reset back to DHCP if something goes wrong:**
```bash
sudo nmcli con mod "CONNECTION_NAME" ipv4.method auto
sudo nmcli con mod "CONNECTION_NAME" ipv4.addresses ""
sudo nmcli con mod "CONNECTION_NAME" ipv4.gateway ""
sudo nmcli con up "CONNECTION_NAME"
```

**Note:** Your SSH session will disconnect after applying changes. Reconnect using the new IP.

Verify the change:
```bash
hostname -I
```

## Step 2: Install Docker

### 2.1 Install Docker
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### 2.2 Add User to Docker Group
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 2.3 Verify Installation
```bash
docker --version
docker compose version
```

## Step 3: Free Port 53

Port 53 is often used by systemd-resolved. Disable it:

```bash
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
```

Verify port 53 is free:
```bash
sudo ss -tulpn | grep :53
```

## Step 4: Clone and Deploy

### 4.1 Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/pi-hole.git ~/pihole
cd ~/pihole
```

### 4.2 Configure Environment

Edit the `.env` file with your preferences:
```bash
nano .env
```

Key settings to change:
- `FTLCONF_webserver_api_password` - Your admin password
- `TZ` - Your timezone (e.g., `America/New_York`)
- `PRIMARY_WEB_PORT` - Web GUI port (default: 8080)

### 4.3 Start the Stack
```bash
docker compose up -d
```

### 4.4 Verify Containers
```bash
docker compose ps
```

Both `pihole` and `unbound` should show as running/healthy.

## Step 5: Access Pi-hole

### Find Your Pi's IP
```bash
hostname -I
```

### Access Web Interface
```
http://<PI_IP>:8080/admin
```

Example: `http://192.168.1.100:8080/admin`

Login with the password from your `.env` file.

## Step 6: Verify Unbound is Working

### Check Pi-hole Upstream DNS
In the Pi-hole web interface:
1. Go to Settings > DNS
2. Verify upstream DNS shows `172.20.0.2#5335` (Unbound)

### Test from Command Line
```bash
# Test Unbound directly
docker exec unbound drill @127.0.0.1 -p 5335 google.com

# Test Pi-hole DNS
dig @localhost google.com
```

## Step 7: Configure Your Router

### Option A: Router DHCP Settings (Recommended)

1. Log into your router admin panel
2. Find DHCP/DNS settings
3. Set DNS server to your Pi's IP address:
   - Primary DNS: `192.168.1.100`
   - Secondary DNS: Leave blank or use a backup

All devices on your network will automatically use Pi-hole.

### Option B: Per-Device Configuration

Manually set DNS on each device to your Pi's IP.

**Windows:**
- Settings > Network & Internet > Change adapter options
- Right-click adapter > Properties > IPv4 > Use the following DNS

**macOS:**
- System Preferences > Network > Advanced > DNS
- Add your Pi's IP

**iOS/Android:**
- WiFi Settings > Your network > Configure DNS > Manual
- Add your Pi's IP

## Step 8: Enable Auto-Start

Create a systemd service:
```bash
sudo nano /etc/systemd/system/pihole.service
```

Add:
```ini
[Unit]
Description=Pi-hole with Unbound
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/pi/pihole
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=pi

[Install]
WantedBy=multi-user.target
```

Enable it:
```bash
sudo systemctl enable pihole.service
```

## Maintenance

### View Logs
```bash
docker compose logs -f pihole
docker compose logs -f unbound
```

### Update Containers
```bash
cd ~/pihole
docker compose pull
docker compose up -d
```

### Restart Services
```bash
docker compose restart
```

### Update Blocklists
```bash
docker exec pihole pihole -g
```

## Troubleshooting

### Containers Won't Start
```bash
docker compose logs
sudo ss -tulpn | grep :53
```

### Can't Access Web Interface
```bash
# Check firewall
sudo ufw status

# Allow ports if needed
sudo ufw allow 8080/tcp
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
```

### DNS Not Working
```bash
# Test Unbound
docker exec unbound drill @127.0.0.1 -p 5335 google.com

# Test Pi-hole
docker exec pihole dig @127.0.0.1 google.com

# Check Pi-hole logs
docker compose logs pihole
```

### Password Not Working
The password is set via `FTLCONF_webserver_api_password` in `.env`. To reset:
```bash
docker compose down
docker compose up -d
```

## Quick Reference

```bash
# Start
cd ~/pihole && docker compose up -d

# Stop
cd ~/pihole && docker compose down

# Restart
cd ~/pihole && docker compose restart

# View logs
cd ~/pihole && docker compose logs -f

# Update
cd ~/pihole && docker compose pull && docker compose up -d

# Status
cd ~/pihole && docker compose ps
```

## Resources

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Unbound Documentation](https://unbound.docs.nlnetlabs.nl/)
- [Pi-hole Docker GitHub](https://github.com/pi-hole/docker-pi-hole)
