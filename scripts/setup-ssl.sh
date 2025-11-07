#!/bin/bash

# SSL Setup Script using Let's Encrypt
# Configures HTTPS for production deployment

set -e

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "Usage: ./setup-ssl.sh yourdomain.com"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SSL_DIR="$PROJECT_DIR/docker/nginx/ssl"

echo "================================================"
echo "SSL/TLS Setup for $DOMAIN"
echo "================================================"
echo ""

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    sudo apt-get update
    sudo apt-get install -y certbot
fi

# Stop nginx if running
docker compose stop nginx 2>/dev/null || true

# Obtain certificate
echo "Obtaining SSL certificate from Let's Encrypt..."
echo "Note: Make sure your domain points to this server's IP address"
echo ""

sudo certbot certonly --standalone \
    -d "$DOMAIN" \
    --agree-tos \
    --no-eff-email \
    --email "${SSL_EMAIL:-admin@$DOMAIN}"

# Copy certificates to nginx ssl directory
echo ""
echo "Copying certificates..."
sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/"
sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/"
sudo chmod 644 "$SSL_DIR/fullchain.pem"
sudo chmod 600 "$SSL_DIR/privkey.pem"

# Update .env file
if [ -f "$PROJECT_DIR/.env" ]; then
    sed -i "s/SSL_ENABLED=false/SSL_ENABLED=true/" "$PROJECT_DIR/.env"
    sed -i "s/SSL_DOMAIN=.*/SSL_DOMAIN=$DOMAIN/" "$PROJECT_DIR/.env"
    echo "✓ Updated .env file"
fi

# Update nginx config
NGINX_CONF="$PROJECT_DIR/docker/nginx/conf.d/default.conf"
if grep -q "# server {" "$NGINX_CONF"; then
    echo "Enabling HTTPS in nginx configuration..."
    sed -i 's/# \(server {\)/\1/' "$NGINX_CONF"
    sed -i 's/# \(    listen 443\)/\1/' "$NGINX_CONF"
    sed -i 's/# \(    ssl_\)/\1/' "$NGINX_CONF"
    sed -i "s/yourdomain.com/$DOMAIN/g" "$NGINX_CONF"
    echo "✓ Nginx configuration updated"
fi

# Setup auto-renewal
echo ""
echo "Setting up automatic certificate renewal..."
(sudo crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet && cp /etc/letsencrypt/live/$DOMAIN/*.pem $SSL_DIR/ && docker compose restart nginx") | sudo crontab -

echo ""
echo "================================================"
echo "✓ SSL/TLS Setup Complete!"
echo "================================================"
echo ""
echo "Your site is now secured with HTTPS"
echo "Certificate will auto-renew every 90 days"
echo ""
echo "Starting nginx with SSL enabled..."
docker compose up -d nginx

echo ""
echo "Access your site at: https://$DOMAIN"
echo "================================================"
