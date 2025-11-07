# Hướng dẫn Nhanh - Quick Start Guide

## Cài đặt nhanh trên Ubuntu/Debian

### 1. Cài đặt Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Clone và Setup

```bash
git clone <repo-url> vietnam-map-server
cd vietnam-map-server
cp .env.example .env
nano .env  # Đổi POSTGRES_PASSWORD
```

### 3. Download dữ liệu

```bash
bash scripts/download-vietnam-data.sh
```

### 4. Import và khởi động

```bash
# Start PostgreSQL
docker compose up -d postgres
sleep 10

# Import OSM (30-60 phút)
docker compose run --rm import-osm

# Prepare routing (15-30 phút)  
docker compose --profile import run --rm osrm-prepare-car

# Start all services
docker compose up -d
```

### 5. Truy cập

- Frontend: http://localhost
- Tile Server: http://localhost:8080
- API Docs: Xem `docs/API.md`

## Commands thường dùng

```bash
# Xem logs
docker compose logs -f

# Stop tất cả
docker compose down

# Restart service
docker compose restart [service-name]

# Backup
bash scripts/backup.sh

# Update OSM data
bash scripts/update-osm-data.sh
```

## Xử lý lỗi nhanh

**Port đã sử dụng:**
```bash
# Đổi port trong .env
NGINX_PORT=8080
```

**Out of memory:**
```bash
# Tạo swap
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**Import thất bại:**
```bash
docker compose down -v
docker compose up -d postgres
sleep 10
docker compose run --rm import-osm
```

## Hỗ trợ

- [Installation Guide](docs/INSTALLATION.md)
- [API Documentation](docs/API.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
