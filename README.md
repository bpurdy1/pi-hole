# Pi-hole Docker Setup

Simple Pi-hole setup with two instances (primary and secondary) for high availability.

## Quick Start

Run the setup script:

```bash
./setup.sh
```

## Manual Setup

If you prefer to set it up manually:

```bash
# Start containers
docker-compose up -d

# Wait for containers to start
sleep 15

# Disable password authentication
docker exec pihole-primary pihole setpassword ""
docker exec pihole-secondary pihole setpassword ""
```

## Access

- **Primary HTTP**: http://localhost:8080/admin
- **Primary HTTPS**: https://localhost:8443/admin
- **Secondary HTTP**: http://localhost:8081/admin
- **Secondary HTTPS**: https://localhost:8444/admin

No password required!

## Configuration

All configuration is in the `.env` file:

- **DNS Servers**: Change `PIHOLE_DNS_` to use different upstream DNS
- **Ports**: Modify `PRIMARY_WEB_PORT`, `SECONDARY_WEB_PORT`, etc.
- **Network**: Change `PIHOLE_SUBNET` if it conflicts with your network

## Set a Password (Optional)

If you want password protection:

```bash
# Set password to "admin"
docker exec pihole-primary pihole setpassword admin
docker exec pihole-secondary pihole setpassword admin
```

## Important Notes

- **No persistent storage**: Data is lost when containers restart
- **Run setup.sh after restart**: Passwords need to be set again after container restart
- **HTTP + HTTPS**: Both protocols available without forced redirects

## Restart Containers

```bash
docker-compose restart
```

After restart, run the password commands again if you want authentication disabled.

## Stop Containers

```bash
docker-compose down
```

## View Logs

```bash
docker logs pihole-primary
docker logs pihole-secondary
```
