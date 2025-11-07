# Hướng dẫn Deploy lên VPS/Server

## Mục lục
1. [Chuẩn bị VPS](#chuẩn-bị-vps)
2. [Bảo mật Server](#bảo-mật-server)
3. [Deploy Application](#deploy-application)
4. [Cấu hình Domain & SSL](#cấu-hình-domain--ssl)
5. [Monitoring & Logging](#monitoring--logging)
6. [Backup & Disaster Recovery](#backup--disaster-recovery)

## Chuẩn bị VPS

### Nhà cung cấp khuyến nghị

**Trong nước:**
- Viettel IDC
- VNPT IDC
- FPT Cloud
- Viettel Cloud

**Quốc tế:**
- DigitalOcean (khuyến nghị)
- Linode
- Vultr
- AWS EC2
- Google Cloud Platform

### Cấu hình VPS khuyến nghị

**Basic (test/development):**
- 4 CPU cores
- 8GB RAM
- 50GB SSD
- 100Mbps bandwidth
- ~$20-40/tháng

**Production:**
- 8 CPU cores
- 16-32GB RAM
- 100GB+ SSD NVMe
- 1Gbps bandwidth
- ~$80-150/tháng

### Hệ điều hành

Ubuntu 22.04 LTS (khuyến nghị) hoặc Ubuntu 20.04 LTS

## Bảo mật Server

### 1. Tạo user mới (không dùng root)

```bash
# SSH vào server với root
ssh root@your-server-ip

# Tạo user mới
adduser mapuser
usermod -aG sudo mapuser

# Chuyển sang user mới
su - mapuser
```

### 2. Cấu hình SSH

```bash
# Tạo SSH key trên máy local (không phải server)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy public key lên server
ssh-copy-id mapuser@your-server-ip

# Trên server, cấu hình SSH
sudo nano /etc/ssh/sshd_config
```

Thay đổi các dòng sau:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:
```bash
sudo systemctl restart sshd
```

### 3. Cấu hình Firewall

```bash
# Cài đặt UFW
sudo apt install ufw

# Cấu hình mặc định
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Kiểm tra status
sudo ufw status verbose
```

### 4. Cài đặt Fail2Ban

```bash
# Cài đặt
sudo apt install fail2ban

# Tạo config
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

Thêm/sửa:
```ini
[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 3600
```

```bash
# Khởi động
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Deploy Application

### 1. Cài đặt dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Cài đặt Docker Compose
sudo apt install docker-compose-plugin

# Cài đặt git
sudo apt install git

# Cài đặt tools khác
sudo apt install htop ncdu wget curl
```

### 2. Clone project

```bash
# Tạo thư mục
mkdir ~/apps
cd ~/apps

# Clone project (hoặc upload qua SCP/SFTP)
git clone <your-repo-url> vietnam-map-server
cd vietnam-map-server
```

### 3. Cấu hình môi trường

```bash
# Copy .env
cp .env.example .env

# Chỉnh sửa
nano .env
```

**Cấu hình quan trọng cho production:**

```bash
# Database - QUAN TRỌNG: Đổi password!
POSTGRES_PASSWORD=your_very_strong_password_123!@#

# Ports
NGINX_PORT=80
NGINX_SSL_PORT=443

# Performance (tùy theo RAM server)
# Với 16GB RAM:
POSTGRES_SHARED_BUFFERS=4GB
POSTGRES_WORK_MEM=256MB
POSTGRES_MAINTENANCE_WORK_MEM=1GB
POSTGRES_EFFECTIVE_CACHE_SIZE=8GB

# SSL
SSL_ENABLED=true
SSL_DOMAIN=yourdomain.com
SSL_EMAIL=your-email@example.com

# Cache
REDIS_ENABLED=true
CACHE_TTL=3600
```

### 4. Download và import dữ liệu

```bash
# Download OSM data
bash scripts/download-vietnam-data.sh

# Start PostgreSQL
docker compose up -d postgres

# Chờ 10 giây
sleep 10

# Import OSM data (mất 30-60 phút)
docker compose run --rm import-osm

# Prepare routing data (mất 15-30 phút)
docker compose --profile import run --rm osrm-prepare-car
```

### 5. Khởi động services

```bash
# Start tất cả services
docker compose up -d

# Xem logs
docker compose logs -f

# Kiểm tra trạng thái
docker compose ps
```

## Cấu hình Domain & SSL

### 1. Cấu hình DNS

Tại nhà cung cấp domain, thêm A record:

```
Type: A
Name: @ (hoặc yourdomain.com)
Value: YOUR_SERVER_IP
TTL: 300

Type: A
Name: www
Value: YOUR_SERVER_IP
TTL: 300
```

Chờ 5-15 phút để DNS propagate.

### 2. Cài đặt SSL với Let's Encrypt

```bash
# Chạy script setup SSL
bash scripts/setup-ssl.sh yourdomain.com

# Hoặc manual:
sudo apt install certbot

# Stop nginx tạm thời
docker compose stop nginx

# Obtain certificate
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem docker/nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem docker/nginx/ssl/
sudo chmod 644 docker/nginx/ssl/fullchain.pem
sudo chmod 600 docker/nginx/ssl/privkey.pem

# Update .env
nano .env
# Set SSL_ENABLED=true

# Restart nginx
docker compose up -d nginx
```

### 3. Auto-renew SSL

```bash
# Setup cron
crontab -e

# Thêm dòng này (renew và reload nginx mỗi ngày)
0 3 * * * certbot renew --quiet && cp /etc/letsencrypt/live/yourdomain.com/*.pem ~/apps/vietnam-map-server/docker/nginx/ssl/ && docker compose -f ~/apps/vietnam-map-server/docker-compose.yml restart nginx
```

## Monitoring & Logging

### 1. Docker logs

```bash
# View logs
docker compose logs -f

# View specific service
docker compose logs -f nginx
docker compose logs -f postgres

# Save logs to file
docker compose logs > logs/docker-$(date +%Y%m%d).log
```

### 2. System monitoring

```bash
# Resource usage
htop

# Docker stats
docker stats

# Disk usage
df -h
ncdu /

# Network
sudo iftop
```

### 3. Setup log rotation

```bash
# Create logrotate config
sudo nano /etc/logrotate.d/vietnam-map-server
```

Thêm:
```
/home/mapuser/apps/vietnam-map-server/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

### 4. Application monitoring (Optional)

Cài đặt Prometheus + Grafana:

```bash
# Thêm vào docker-compose.yml hoặc tạo docker-compose.monitoring.yml
# Xem ví dụ tại: https://github.com/stefanprodan/dockprom
```

## Backup & Disaster Recovery

### 1. Setup backup tự động

```bash
# Tạo backup directory
mkdir -p ~/backups

# Setup cron cho backup hàng ngày
crontab -e
```

Thêm:
```bash
# Backup database mỗi ngày lúc 2h sáng
0 2 * * * /home/mapuser/apps/vietnam-map-server/scripts/backup.sh

# Clean old backups (giữ 30 ngày)
0 3 * * * find /home/mapuser/backups -name "*.sql.gz" -mtime +30 -delete
```

### 2. Backup sang cloud storage

```bash
# Cài đặt rclone
curl https://rclone.org/install.sh | sudo bash

# Cấu hình rclone với cloud provider (DigitalOcean Spaces, AWS S3, Google Drive, etc)
rclone config

# Backup script với rclone
cat > ~/backup-to-cloud.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=~/backups
REMOTE_NAME=digitalocean  # Tên remote đã config trong rclone
BUCKET_NAME=vietnam-map-backups

# Backup database
~/apps/vietnam-map-server/scripts/backup.sh

# Upload to cloud
rclone sync $BACKUP_DIR $REMOTE_NAME:$BUCKET_NAME --progress

# Clean local old backups
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
EOF

chmod +x ~/backup-to-cloud.sh

# Add to cron
crontab -e
# 0 3 * * * /home/mapuser/backup-to-cloud.sh
```

### 3. Restore from backup

```bash
# List backups
ls -lh ~/backups/

# Restore database
gunzip -c ~/backups/mapdb_backup_20240101_020000.sql.gz | \
  docker compose exec -T postgres psql -U mapuser mapdb

# Hoặc dùng script
bash scripts/restore.sh ~/backups/mapdb_backup_20240101_020000.sql.gz
```

## Performance Optimization

### 1. Optimize PostgreSQL

```bash
# Edit postgresql.conf
nano docker/postgres/postgresql.conf
```

Với 16GB RAM:
```conf
shared_buffers = 4GB
effective_cache_size = 12GB
maintenance_work_mem = 1GB
work_mem = 256MB
max_connections = 200
```

### 2. Setup Redis cache

```bash
# Bật Redis trong .env
nano .env
# Set REDIS_ENABLED=true

# Start Redis
docker compose --profile full up -d redis
```

### 3. CDN cho tiles

Sử dụng CloudFlare (free) hoặc AWS CloudFront:

1. Add domain vào CloudFlare
2. Enable caching rules cho `/tiles/*`
3. Set cache TTL = 7 days

## Troubleshooting Production

### Service không khởi động

```bash
# Xem logs chi tiết
docker compose logs [service-name]

# Restart service
docker compose restart [service-name]

# Rebuild
docker compose up -d --build [service-name]
```

### Database connection issues

```bash
# Check PostgreSQL
docker compose exec postgres psql -U mapuser -d mapdb -c "SELECT version();"

# Check connections
docker compose exec postgres psql -U mapuser -d mapdb -c "SELECT * FROM pg_stat_activity;"
```

### High CPU/Memory usage

```bash
# Check resource usage
docker stats

# Check PostgreSQL queries
docker compose exec postgres psql -U mapuser -d mapdb -c "SELECT pid, query, state FROM pg_stat_activity WHERE state != 'idle';"

# Kill long-running queries
docker compose exec postgres psql -U mapuser -d mapdb -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < NOW() - INTERVAL '10 minutes';"
```

## Checklist Deploy Production

- [ ] Server đã được bảo mật (SSH key, firewall, fail2ban)
- [ ] Database password đã được thay đổi
- [ ] SSL certificate đã được cài đặt
- [ ] DNS đã được cấu hình
- [ ] Backup tự động đã được setup
- [ ] Monitoring đã được cài đặt
- [ ] Log rotation đã được cấu hình
- [ ] Firewall rules đã được kiểm tra
- [ ] Rate limiting đã được enable
- [ ] Cache đã được cấu hình
- [ ] Performance tuning đã được thực hiện

## Hỗ trợ

Nếu gặp vấn đề khi deploy, tham khảo:
- File INSTALLATION.md
- File API.md
- Logs: `docker compose logs -f`
- GitHub Issues
