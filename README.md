# Vietnam Map Server - Hệ thống Bản đồ Việt Nam

Một hệ thống tile server hoàn chỉnh với đầy đủ tính năng routing, geocoding, matrix, isochrone sử dụng dữ liệu OpenStreetMap cho Việt Nam.

## 🚀 Tính năng

- ✅ **Tile Server**: Phục vụ map tiles vector/raster
- ✅ **Routing**: Tìm đường đi giữa 2 điểm
- ✅ **Geocoding**: Chuyển đổi địa chỉ <-> tọa độ
- ✅ **Reverse Geocoding**: Tìm địa chỉ từ tọa độ
- ✅ **Route Optimization**: Tối ưu hóa đường đi nhiều điểm
- ✅ **Distance Matrix**: Ma trận khoảng cách giữa nhiều điểm
- ✅ **Isochrone**: Vùng phủ sóng theo thời gian/khoảng cách

## 🏗️ Kiến trúc

```
┌─────────────────────────────────────────────────────────┐
│                     Nginx (Reverse Proxy)                │
│                    Port 80/443 (HTTPS)                   │
└──────────────┬──────────────────────────────────────────┘
               │
    ┌──────────┴──────────┬─────────────┬──────────────┐
    ▼                     ▼             ▼              ▼
┌─────────┐         ┌──────────┐   ┌────────┐   ┌──────────┐
│ Tile    │         │ Routing  │   │Geocode │   │ Frontend │
│ Server  │         │  (OSRM)  │   │(Nomina)│   │  (Web)   │
│ :8080   │         │  :5000   │   │ :7070  │   │  :3000   │
└────┬────┘         └────┬─────┘   └───┬────┘   └──────────┘
     │                   │             │
     └───────────────────┴─────────────┘
                         │
                ┌────────▼────────┐
                │   PostgreSQL    │
                │   + PostGIS     │
                │     :5432       │
                └─────────────────┘
```

## 📋 Yêu cầu hệ thống

### Tối thiểu (cho Việt Nam)
- **CPU**: 4 cores
- **RAM**: 8GB (khuyến nghị 16GB)
- **Disk**: 50GB SSD
- **OS**: Ubuntu 20.04/22.04 hoặc Debian 11/12

### Khuyến nghị (Production)
- **CPU**: 8+ cores
- **RAM**: 32GB+
- **Disk**: 100GB+ SSD NVMe
- **Bandwidth**: 100Mbps+

## 🛠️ Cài đặt

### Bước 1: Chuẩn bị môi trường

```bash
# Clone repository
git clone <your-repo-url>
cd newmap

# Cài đặt Docker và Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install docker-compose-plugin
```

### Bước 2: Download dữ liệu OpenStreetMap Việt Nam

```bash
# Tạo thư mục data
mkdir -p data/osm data/tiles data/routing

# Download Vietnam OSM data (khoảng 1.5GB)
cd data/osm
wget https://download.geofabrik.de/asia/vietnam-latest.osm.pbf

# Hoặc dùng script tự động
cd ../..
bash scripts/download-vietnam-data.sh
```

### Bước 3: Khởi động hệ thống

```bash
# Khởi động tất cả services
docker-compose up -d

# Xem logs
docker-compose logs -f

# Kiểm tra trạng thái
docker-compose ps
```

### Bước 4: Import dữ liệu (chạy lần đầu)

```bash
# Import OSM data vào PostgreSQL + PostGIS
docker-compose run --rm import-osm

# Tạo routing data cho OSRM
docker-compose run --rm import-routing

# Import dữ liệu geocoding
docker-compose run --rm import-geocoding
```

Quá trình import có thể mất 30-60 phút tùy vào cấu hình máy.

### Bước 5: Truy cập các services

- **Frontend Demo**: http://localhost (hoặc http://your-server-ip)
- **Tile Server**: http://localhost/tiles
- **Routing API**: http://localhost/route
- **Geocoding API**: http://localhost/geocode
- **API Documentation**: http://localhost/docs

## 📚 Sử dụng API

### 1. Routing - Tìm đường

```bash
# Tìm đường từ Hà Nội đến Hồ Chí Minh
curl "http://localhost/route/v1/driving/105.8342,21.0278;106.6297,10.8231?overview=full&steps=true"
```

```javascript
// JavaScript/TypeScript
const response = await fetch(
  'http://localhost/route/v1/driving/105.8342,21.0278;106.6297,10.8231?overview=full'
);
const data = await response.json();
console.log(data.routes[0].distance); // Khoảng cách (mét)
console.log(data.routes[0].duration); // Thời gian (giây)
```

### 2. Geocoding - Tìm tọa độ từ địa chỉ

```bash
# Forward geocoding
curl "http://localhost/geocode/search?q=Hồ+Gươm+Hà+Nội&format=json"
```

```javascript
const response = await fetch(
  'http://localhost/geocode/search?q=Hồ Gươm Hà Nội&format=json'
);
const data = await response.json();
console.log(data[0].lat, data[0].lon);
```

### 3. Reverse Geocoding - Tìm địa chỉ từ tọa độ

```bash
curl "http://localhost/geocode/reverse?lat=21.0285&lon=105.8542&format=json"
```

### 4. Distance Matrix - Ma trận khoảng cách

```bash
# Ma trận khoảng cách giữa nhiều điểm
curl "http://localhost/route/v1/table/105.8342,21.0278;106.6297,10.8231;108.2022,16.0544?annotations=distance,duration"
```

### 5. Isochrone - Vùng phủ sóng

```bash
# Vùng có thể đi được trong 10, 20, 30 phút
curl "http://localhost/route/v1/isochrone/105.8342,21.0278?contours_minutes=10,20,30"
```

### 6. Route Optimization - Tối ưu hóa tuyến đường

```bash
# Tối ưu hóa thứ tự ghé thăm nhiều điểm
curl "http://localhost/route/v1/trip/105.8342,21.0278;105.8442,21.0378;105.8542,21.0478?source=first&destination=last&roundtrip=true"
```

## 🔧 Cấu hình nâng cao

### Tùy chỉnh port

Chỉnh sửa file `.env`:

```bash
# Ports
NGINX_PORT=80
NGINX_SSL_PORT=443
TILESERVER_PORT=8080
ROUTING_PORT=5000
GEOCODING_PORT=7070
FRONTEND_PORT=3000
POSTGRES_PORT=5432
```

### Cấu hình HTTPS/SSL

```bash
# Cài đặt Let's Encrypt SSL
bash scripts/setup-ssl.sh yourdomain.com
```

### Backup dữ liệu

```bash
# Backup database
bash scripts/backup.sh

# Restore database
bash scripts/restore.sh backup-2024-01-01.sql
```

## 🗺️ Mở rộng phạm vi

### Thêm khu vực khác

```bash
# Download thêm dữ liệu (ví dụ: Thái Lan)
cd data/osm
wget https://download.geofabrik.de/asia/thailand-latest.osm.pbf

# Hoặc toàn bộ Đông Nam Á
wget https://download.geofabrik.de/asia/southeast-asia-latest.osm.pbf

# Import lại
docker-compose run --rm import-osm
```

### Cập nhật dữ liệu định kỳ

```bash
# Cài đặt cron job cập nhật hàng tuần
crontab -e

# Thêm dòng này (cập nhật mỗi Chủ nhật 2h sáng)
0 2 * * 0 /path/to/newmap/scripts/update-osm-data.sh
```

## 📊 Monitoring & Performance

### Xem metrics

```bash
# Resource usage
docker stats

# Service logs
docker-compose logs -f [service-name]

# Database performance
docker-compose exec postgres psql -U mapuser -d mapdb -c "SELECT * FROM pg_stat_activity;"
```

### Tối ưu hiệu năng

1. **Tăng cache cho PostgreSQL**: Sửa `docker/postgres/postgresql.conf`
2. **CDN cho tiles**: Dùng CloudFlare hoặc AWS CloudFront
3. **Load balancing**: Chạy nhiều instance OSRM/Nominatim

## 🐛 Troubleshooting

### Service không khởi động

```bash
# Kiểm tra logs
docker-compose logs [service-name]

# Restart service
docker-compose restart [service-name]

# Rebuild
docker-compose down
docker-compose up -d --build
```

### Import thất bại

```bash
# Xóa dữ liệu cũ và import lại
docker-compose down -v
docker-compose up -d postgres
docker-compose run --rm import-osm
```

### Thiếu RAM

```bash
# Tăng swap space
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 📖 Tài liệu tham khảo

- [OpenStreetMap](https://www.openstreetmap.org/)
- [OSRM Documentation](http://project-osrm.org/)
- [Nominatim Documentation](https://nominatim.org/release-docs/latest/)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [MapLibre GL JS](https://maplibre.org/)

## 🤝 Đóng góp

Pull requests welcome! Vui lòng tạo issue trước khi làm các thay đổi lớn.

## 📄 License

MIT License - Xem file LICENSE để biết thêm chi tiết

## 💬 Hỗ trợ

- Tạo [Issue](https://github.com/yourname/newmap/issues) nếu gặp vấn đề
- Email: your-email@example.com

## 🎯 Roadmap

- [ ] Hỗ trợ routing cho xe máy, đi bộ
- [ ] Traffic data integration
- [ ] POI (Points of Interest) search
- [ ] 3D buildings
- [ ] Offline mobile SDK
- [ ] Real-time traffic updates

---

**Made with ❤️ for Vietnam**
