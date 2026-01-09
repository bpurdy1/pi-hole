.PHONY: up down restart logs clean clean-all setup

# Start containers
up:
	docker compose up -d

# Stop containers
down:
	docker compose down

# Restart containers
restart:
	docker compose restart

# View logs
logs:
	docker compose logs -f

# Update and restart
update:
	docker compose pull
	docker compose up -d

# Clean Pi-hole data only
clean-pihole:
	docker compose down
	rm -rf pihole/etc-pihole/*
	rm -rf pihole/etc-dnsmasq.d/*

# Clean Unbound data only (keeps config)
clean-unbound:
	docker compose down
	rm -rf unbound/unbound.pid
	rm -rf unbound/var/

# Clean all data (keeps configs)
clean:
	docker compose down
	rm -rf pihole/etc-pihole/*
	rm -rf pihole/etc-dnsmasq.d/*
	rm -rf unbound/unbound.pid
	rm -rf unbound/var/

# Clean everything (full reset - removes all data and directories)
clean-all:
	docker compose down -v
	rm -rf pihole/
	rm -rf unbound/unbound.pid
	rm -rf unbound/var/

# Initial setup - create directories and copy env
setup:
	mkdir -p pihole/etc-pihole
	mkdir -p pihole/etc-dnsmasq.d
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example - edit it with your settings"; fi

# Show status
status:
	docker compose ps

# Update gravity (blocklists)
gravity:
	docker exec pihole pihole -g

# Test DNS
test:
	@echo "Testing Unbound..."
	docker exec unbound drill @127.0.0.1 google.com
	@echo "\nTesting Pi-hole..."
	docker exec pihole dig @127.0.0.1 google.com +short
