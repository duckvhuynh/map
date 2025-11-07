# 🚀 Deploy Hoàn Chỉnh Lên Coolify - Hướng Dẫn Đầy Đủ

**Deploy tất cả services một lần qua GitHub repo!**

---

## 📋 Tổng Quan Hệ Thống

Sau khi deploy, bạn sẽ có **9 services** chạy hoàn toàn tự động:

| Service | Mô Tả | Port | Status |
|---------|-------|------|--------|
| **Frontend** | Next.js web app | 3000 | ✅ Public (qua Traefik) |
| **PostgreSQL** | Database + PostGIS | 5432 | 🔒 Internal |
| **TileServer** | Raster map tiles | 8080 | 🔒 Internal |
| **OSRM Car** | Car routing | 5000 | 🔒 Internal |
| **OSRM Bike** | Bike routing | 5001 | 🔒 Internal |
| **OSRM Foot** | Foot routing | 5002 | 🔒 Internal |
| **Nominatim** | Geocoding | 8081 | 🔒 Internal |
| **Martin** | Vector tiles | 3001 | 🔒 Internal |
| **Redis** | Cache | 6379 | 🔒 Internal |

**Chỉ có Frontend được expose public qua Traefik!**

---

## ⚡ Quick Start (3 Bước Chính)

### Bước 1: Tạo Application Trong Coolify

1. Mở Coolify Dashboard
2. **Projects** → **New Project**
   - Name: `Vietnam Map Server`
   - Description: `Self-hosted map system for Vietnam`
3. Click vào Project vừa tạo
4. **New** → **Application**
5. **Source Type**: GitHub
   - Repository: `duckvhuynh/map`
   - Branch: `main`
6. **Build Pack**: Docker Compose
7. **Compose File Path**: `docker-compose.coolify.yml`

### Bước 2: Cấu Hình Environment Variables

Trong Coolify, tab **Environment Variables**, add các biến sau:

```env
# Application
APP_NAME=vietnam-map-server
APP_DOMAIN=map.duckvhuynh.space
APP_URL=https://map.duckvhuynh.space

# PostgreSQL (QUAN TRỌNG: Tạo password mạnh!)
POSTGRES_DB=mapdb
POSTGRES_USER=mapuser
POSTGRES_PASSWORD=YOUR_STRONG_PASSWORD_HERE

# PostgreSQL Performance
POSTGRES_SHARED_BUFFERS=2GB
POSTGRES_WORK_MEM=256MB
POSTGRES_MAINTENANCE_WORK_MEM=1GB
POSTGRES_MAX_CONNECTIONS=200

# Nominatim
NOMINATIM_THREADS=4
```

**Tạo password mạnh:**
```bash
openssl rand -base64 32
```

### Bước 3: Deploy!

1. Click **Deploy** button
2. Đợi Coolify build và start tất cả services (~5-10 phút)
3. Kiểm tra logs để đảm bảo không có lỗi

---

## 📦 Chuẩn Bị Dữ Liệu (Chạy Sau Khi Deploy)

### 3.1. SSH vào VPS

```bash
ssh root@your-vps-ip
```

### 3.2. Tìm Application Directory

```bash
# Coolify lưu apps tại đây
cd /data/coolify/applications

# Tìm app của bạn (tên có thể là hash)
ls -la

# Hoặc tìm theo project name
find . -name "docker-compose.coolify.yml" 2>/dev/null

# Ví dụ path:
cd /data/coolify/applications/abc123xyz
```

### 3.3. Chạy Setup Script

```bash
# Download Vietnam OSM data và cấu hình
bash setup-coolify.sh
```

Script này sẽ:
- ✅ Tạo thư mục `data/osm` và `data/routing`
- ✅ Download `vietnam-latest.osm.pbf` (~301MB) từ Geofabrik
- ✅ Download OpenStreetMap Carto style và Lua config
- ✅ Download OSRM routing profiles (car/bike/foot) + lib directory
- ✅ Tạo PostgreSQL và TileServer configs

**Thời gian:** ~5-10 phút (tùy tốc độ mạng)

### 3.4. Import Dữ Liệu OSM

```bash
# Import OSM vào PostgreSQL và chuẩn bị OSRM routing
bash import-data.sh
```

Script này sẽ:
- ✅ Đợi PostgreSQL sẵn sàng
- ✅ Import OSM data vào database (~30-60 phút)
- ✅ Prepare OSRM car routing (~10-20 phút)
- ✅ Prepare OSRM bike routing (~10-20 phút)
- ✅ Prepare OSRM foot routing (~10-20 phút)
- ✅ Tạo spatial indexes
- ✅ Optimize database (VACUUM ANALYZE)

**Tổng thời gian:** ~60-120 phút

**Theo dõi progress:**
```bash
# Xem logs import OSM
docker logs -f map-postgres

# Xem logs OSRM prepare
docker logs -f map-osrm-car
docker logs -f map-osrm-bike
docker logs -f map-osrm-foot
```

### 3.5. Restart Services

Sau khi import xong:

1. Quay lại Coolify Dashboard
2. Vào application của bạn
3. Click **Restart All** để reload tất cả services với data mới

---

## ✅ Kiểm Tra Deployment

### Test Frontend

```bash
curl https://map.duckvhuynh.space/
```

Kết quả: HTML của trang chủ

### Test Health Endpoint

```bash
curl https://map.duckvhuynh.space/api/health
```

Kết quả:
```json
{
  "status": "ok",
  "timestamp": "2025-11-08T10:30:00.000Z",
  "service": "vietnam-map-frontend"
}
```

### Test Tiles

```bash
curl -I https://map.duckvhuynh.space/tiles/0/0/0.png
```

Kết quả: `HTTP/2 200`

### Test Geocoding

```bash
curl "https://map.duckvhuynh.space/geocode?q=Hanoi"
```

Kết quả: JSON với địa chỉ Hà Nội

### Test Routing

```bash
curl "https://map.duckvhuynh.space/route?start=105.8342,21.0278&end=106.6297,10.8231&profile=car"
```

Kết quả: JSON với route từ Hà Nội đến TP.HCM

---

## 🔍 Monitoring & Logs

### Xem Logs Trong Coolify

1. Mở Coolify Dashboard
2. Vào application của bạn
3. Tab **Logs**
4. Chọn service muốn xem logs

### Xem Logs Qua Terminal

```bash
# Tất cả services
docker-compose -f docker-compose.coolify.yml logs -f

# Specific service
docker logs -f map-frontend
docker logs -f map-postgres
docker logs -f map-osrm-car
docker logs -f map-nominatim
```

### Kiểm Tra Health

```bash
# Tất cả containers
docker ps | grep map-

# Health status chi tiết
docker inspect map-frontend --format='{{.State.Health.Status}}'
docker inspect map-postgres --format='{{.State.Health.Status}}'
```

---

## 🛠️ Troubleshooting

### ❌ Services không start

**Kiểm tra:**
```bash
docker ps -a | grep map-
```

**Xem logs:**
```bash
docker logs map-frontend
docker logs map-postgres
```

**Fix:**
- Check environment variables trong Coolify
- Đảm bảo POSTGRES_PASSWORD đã được set
- Restart services

### ❌ Import data thất bại

**Nguyên nhân:** Không đủ disk space

**Kiểm tra:**
```bash
df -h
```

**Yêu cầu:** Tối thiểu **50GB** free space

**Fix:**
- Xóa data cũ: `rm -rf data/`
- Tăng disk size trên VPS
- Chạy lại `bash import-data.sh`

### ❌ Out of Memory

**Nguyên nhân:** PostgreSQL hoặc OSRM dùng quá nhiều RAM

**Fix trong Coolify:**
Giảm memory settings:
```env
POSTGRES_SHARED_BUFFERS=1GB
POSTGRES_WORK_MEM=128MB
POSTGRES_MAINTENANCE_WORK_MEM=512MB
```

**Fix trong VPS:**
```bash
# Tạo swap file (nếu chưa có)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### ❌ Routing không hoạt động

**Nguyên nhân:** OSRM data chưa được prepare

**Check:**
```bash
ls -lh data/routing/car/
ls -lh data/routing/bike/
ls -lh data/routing/foot/
```

**Kết quả mong đợi:** Các file `.osrm`, `.osrm.edges`, `.osrm.nbg_nodes`, etc.

**Fix:**
```bash
bash import-data.sh
```

### ❌ Geocoding trả về empty results

**Nguyên nhân:** Nominatim chưa import xong

**Check:**
```bash
docker logs map-nominatim | tail -50
```

**Fix:**
- Đợi Nominatim import hoàn tất (có thể mất 1-2 giờ)
- Restart Nominatim: `docker restart map-nominatim`

### ❌ SSL/TLS errors

**Nguyên nhân:** Traefik chưa generate cert

**Check trong Coolify:**
- Tab **Domains** → Xem status của SSL cert
- Đảm bảo domain đã point DNS đúng về VPS IP

**Fix:**
1. Kiểm tra DNS: `nslookup map.duckvhuynh.space`
2. Đợi Traefik generate cert (2-5 phút)
3. Restart Traefik nếu cần

---

## 🔧 Bảo Trì & Cập Nhật

### Cập Nhật OSM Data (Hàng Tháng)

```bash
cd /data/coolify/applications/your-app-id

# Download data mới
cd data/osm
wget -O vietnam-latest.osm.pbf https://download.geofabrik.de/asia/vietnam-latest.osm.pbf

# Re-import
cd ../..
bash import-data.sh

# Restart services
docker-compose -f docker-compose.coolify.yml restart
```

### Backup Database

```bash
# Backup PostgreSQL
docker exec map-postgres pg_dump -U mapuser mapdb > backup-$(date +%Y%m%d).sql

# Compress
gzip backup-$(date +%Y%m%d).sql

# Upload to S3, Google Drive, etc.
```

### Restore Database

```bash
# Stop services
docker-compose -f docker-compose.coolify.yml stop frontend tileserver osrm-car osrm-bike osrm-foot nominatim martin

# Restore
gunzip -c backup-20251108.sql.gz | docker exec -i map-postgres psql -U mapuser mapdb

# Restart
docker-compose -f docker-compose.coolify.yml start
```

### Update Code (Frontend)

1. Push changes to GitHub
2. Trong Coolify: Click **Redeploy**
3. Coolify sẽ tự động pull code mới và rebuild

---

## 📊 Performance Optimization

### Database Tuning

**Sau khi import xong, chạy:**
```bash
docker exec map-postgres psql -U mapuser mapdb -c "VACUUM ANALYZE;"
docker exec map-postgres psql -U mapuser mapdb -c "REINDEX DATABASE mapdb;"
```

### Cache Strategy

**Redis đã được config với:**
- Max memory: 512MB
- Eviction: allkeys-lru (xóa key ít dùng nhất)

**Để tăng cache:**
```env
# Trong docker-compose.coolify.yml, sửa Redis command:
command: redis-server --appendonly yes --maxmemory 1gb --maxmemory-policy allkeys-lru
```

### Tile Caching

**Sử dụng browser cache headers:**
Frontend đã config Next.js rewrites với cache headers.

### Connection Pooling

**PostgreSQL max connections:**
```env
POSTGRES_MAX_CONNECTIONS=200
```

Tăng nếu có nhiều requests đồng thời.

---

## 🔐 Security

### Firewall Rules

**Chỉ mở ports cần thiết:**
```bash
# UFW
sudo ufw allow 80/tcp    # HTTP (redirect to HTTPS)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 22/tcp    # SSH
sudo ufw enable
```

### SSL Certificate

**Traefik tự động:**
- Generate Let's Encrypt cert
- Auto-renew mỗi 90 ngày
- HTTPS redirect tự động

### Database Security

**PostgreSQL:**
- ✅ Chỉ internal network access
- ✅ Strong password (generated)
- ✅ No public exposure

### Service Isolation

**Docker networks:**
- `mapnet`: Internal services communication
- `coolify`: Chỉ frontend expose ra ngoài

---

## 📈 Scaling

### Horizontal Scaling

**Tăng số replicas cho frontend:**

Trong `docker-compose.coolify.yml`:
```yaml
frontend:
  deploy:
    replicas: 3  # Chạy 3 instances
```

### Vertical Scaling

**Tăng resources cho services:**

```yaml
postgres:
  deploy:
    resources:
      limits:
        cpus: '4'
        memory: 8G
```

### Load Balancing

**Traefik tự động load balance** nếu có multiple replicas.

---

## 🆘 Support & Resources

### Documentation

- **Quick Start**: [QUICKSTART_COOLIFY.md](./QUICKSTART_COOLIFY.md)
- **Full Guide**: [COOLIFY_DEPLOY.md](./COOLIFY_DEPLOY.md)
- **API Docs**: [API.md](./API.md)
- **Cleanup**: [CLEANUP.md](./CLEANUP.md)

### External Resources

- **Coolify**: https://coolify.io/docs
- **OSRM**: https://project-osrm.org/docs/
- **Nominatim**: https://nominatim.org/release-docs/latest/
- **PostGIS**: https://postgis.net/documentation/
- **MapLibre**: https://maplibre.org/maplibre-gl-js/docs/

### Community

- **GitHub Issues**: https://github.com/duckvhuynh/map/issues
- **Coolify Discord**: https://coolify.io/discord

---

## ✨ Features Sau Khi Deploy

✅ **Self-hosted map tiles** cho Vietnam
✅ **Geocoding** (address → coordinates)
✅ **Reverse geocoding** (coordinates → address)
✅ **Car routing** (fastest routes)
✅ **Bike routing** (bike-friendly routes)
✅ **Foot routing** (pedestrian paths)
✅ **Vector tiles** (smooth, zoomable)
✅ **Automatic SSL** (Let's Encrypt)
✅ **Health monitoring** (Coolify dashboard)
✅ **Auto-restart** on failure
✅ **Zero-downtime updates** (via Coolify)
✅ **Scalable architecture** (horizontal + vertical)

---

## 🎯 Roadmap

- [ ] Add map search UI
- [ ] Add route planning UI
- [ ] Add POI markers (restaurants, hotels, etc.)
- [ ] Add isochrone API (reachability maps)
- [ ] Add map comparison tool
- [ ] Add offline tile support
- [ ] Add mobile app

---

**Made with ❤️ for Vietnam**

Deploy successful! Enjoy your self-hosted map system! 🗺️🇻🇳
