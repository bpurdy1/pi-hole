#!/bin/bash
# Pi-hole Setup Script

echo "Setting up Pi-hole containers..."

# Stop and remove existing containers
docker-compose down

# Start containers (password from .env is loaded automatically)
docker-compose up -d

echo ""
echo "Pi-hole setup complete!"
echo ""
echo "Access your Pi-hole instances:"
echo "  Primary HTTP:    http://localhost:8080/admin"
echo "  Primary HTTPS:   https://localhost:8443/admin"
echo "  Secondary HTTP:  http://localhost:8081/admin"
echo "  Secondary HTTPS: https://localhost:8444/admin"
echo ""

