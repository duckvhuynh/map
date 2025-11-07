# Vietnam Map Server - Tổng quan Dự án

## 📖 Giới thiệu

Dự án này là một **hệ thống bản đồ hoàn chỉnh** cho Việt Nam, tương tự như GrabMaps hay XanhSM Map, sử dụng dữ liệu OpenStreetMap (OSM). Bạn có thể tự host trên server/VPS của mình.

## 🎯 Tính năng chính

### 1. **Tile Server** - Hiển thị bản đồ
- Phục vụ map tiles (raster và vector)
- Hỗ trợ zoom từ level 0-18
- Cache thông minh để tăng tốc độ

### 2. **Routing** - Tìm đường
- Tính toán đường đi tối ưu giữa 2 điểm
- Hỗ trợ nhiều phương tiện: ô tô, xe đạp, đi bộ
- Chỉ dẫn từng bước (turn-by-turn navigation)
- Tính toán khoảng cách và thời gian

### 3. **Geocoding** - Tìm kiếm địa điểm
- **Forward geocoding**: Từ địa chỉ → tọa độ
  - Ví dụ: "Hồ Gươm, Hà Nội" → (21.0285, 105.8542)
- **Reverse geocoding**: Từ tọa độ → địa chỉ
  - Ví dụ: (21.0285, 105.8542) → "Hồ Hoàn Kiếm, Hà Nội"

### 4. **Distance Matrix** - Ma trận khoảng cách
- Tính khoảng cách và thời gian giữa nhiều điểm
- Hữu ích cho logistics, delivery

### 5. **Route Optimization** - Tối ưu hóa tuyến đường
- Giải bài toán TSP (Traveling Salesman Problem)
- Tìm thứ tự tối ưu để đi qua nhiều điểm
- Tiết kiệm thời gian và chi phí

### 6. **Isochrone** - Vùng phủ sóng
- Hiển thị vùng có thể đi được trong X phút/km
- Hữu ích cho phân tích địa lý, real estate

## 🏗️ Kiến trúc hệ thống

```
                    ┌─────────────┐
                    │   Nginx     │  ← Reverse proxy, SSL, rate limit
                    │   Port 80   │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌───────────────┐  ┌──────────────┐  ┌──────────────┐
│  Tile Server  │  │    OSRM      │  │  Nominatim   │
│  (Map tiles)  │  │  (Routing)   │  │  (Geocoding) │
│   Port 8080   │  │  Port 5000   │  │  Port 7070   │
└───────┬───────┘  └──────┬───────┘  └──────┬───────┘
        └──────────────────┼──────────────────┘
                           ▼
                  ┌────────────────┐
                  │   PostgreSQL   │  ← Database lưu trữ OSM
                  │   + PostGIS    │
                  │   Port 5432    │
                  └────────────────┘
```

## 📦 Các thành phần

### Backend Services

1. **PostgreSQL + PostGIS**
   - Database chính lưu trữ dữ liệu OSM
   - PostGIS: Extension cho GIS (Geographic Information System)

2. **OSRM (Open Source Routing Machine)**
   - Engine tính toán routing
   - Hỗ trợ car, bike, foot profiles
   - Cực kỳ nhanh (< 100ms cho mỗi route)

3. **Nominatim**
   - Geocoding service
   - Search địa điểm, tìm tọa độ

4. **TileServer GL / Martin**
   - Phục vụ map tiles
   - Hỗ trợ vector tiles và raster tiles

5. **Nginx**
   - Reverse proxy
   - Load balancing
   - SSL/TLS termination
   - Rate limiting
   - Caching

### Frontend

- **Next.js 14** (React framework)
- **MapLibre GL JS** (hiển thị bản đồ)
- **TypeScript**
- **Tailwind CSS**

## 💻 Yêu cầu hệ thống

### Cho Việt Nam (Development)
- **CPU**: 4 cores
- **RAM**: 8GB (16GB khuyến nghị)
- **Disk**: 50GB SSD
- **OS**: Ubuntu 20.04+, Debian 11+, hoặc Windows với WSL2

### Production
- **CPU**: 8+ cores
- **RAM**: 32GB+
- **Disk**: 100GB+ SSD NVMe
- **Bandwidth**: 1Gbps

## 🚀 Cách sử dụng

### Cài đặt cơ bản

```bash
# 1. Clone project
git clone <repo-url> vietnam-map-server
cd vietnam-map-server

# 2. Cấu hình
cp .env.example .env
nano .env  # Đổi POSTGRES_PASSWORD

# 3. Download dữ liệu Việt Nam (~1.5GB)
bash scripts/download-vietnam-data.sh

# 4. Import dữ liệu (30-60 phút)
docker compose up -d postgres
sleep 10
docker compose run --rm import-osm

# 5. Chuẩn bị routing (15-30 phút)
docker compose --profile import run --rm osrm-prepare-car

# 6. Khởi động tất cả
docker compose up -d
```

### Truy cập

- **Frontend**: http://localhost
- **API Documentation**: Xem `docs/API.md`

## 📚 Dữ liệu

### Nguồn dữ liệu: OpenStreetMap (OSM)

- **License**: ODbL (Open Database License)
- **Cập nhật**: Hàng ngày từ Geofabrik
- **Kích thước**: ~1.5GB cho Việt Nam
- **Free**: Hoàn toàn miễn phí

### Download nguồn khác

Nếu muốn mở rộng sang các nước khác:

```bash
# Thái Lan
wget https://download.geofabrik.de/asia/thailand-latest.osm.pbf

# Toàn bộ Đông Nam Á
wget https://download.geofabrik.de/asia/southeast-asia-latest.osm.pbf

# Toàn thế giới (cẩn thận, > 70GB)
wget https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf
```

## 🔧 Các use cases thực tế

### 1. Ứng dụng gọi xe (Ride-hailing)
```javascript
// Tính đường từ điểm đón đến điểm đến
const route = await getRoute(pickupLocation, dropoffLocation)
console.log(`Khoảng cách: ${route.distance}m`)
console.log(`Thời gian: ${route.duration}s`)
```

### 2. Ứng dụng giao hàng (Delivery)
```javascript
// Tối ưu hóa tuyến đi qua nhiều điểm giao hàng
const optimizedRoute = await optimizeTrip([
  warehouse,
  customer1,
  customer2,
  customer3,
  // ...
])
```

### 3. Tìm kiếm địa điểm
```javascript
// Tìm tọa độ từ địa chỉ
const location = await geocode("Nhà hát lớn Hà Nội")
```

### 4. Phân tích thị trường
```javascript
// Vùng có thể đi được trong 15 phút từ cửa hàng
const isochrone = await getIsochrone(storeLocation, [15])
// → Hiển thị vùng khách hàng tiềm năng
```

## 📊 So sánh với các giải pháp khác

| Tính năng | Vietnam Map Server | Google Maps API | Mapbox |
|-----------|-------------------|-----------------|--------|
| Chi phí | **Free** (self-host) | Trả phí theo lượt | Trả phí theo lượt |
| Data ownership | **Bạn sở hữu** | Google | Mapbox |
| Customization | **Hoàn toàn** | Hạn chế | Trung bình |
| Privacy | **100%** | Google thu thập | Thu thập dữ liệu |
| Vietnam coverage | **Tốt** | Rất tốt | Tốt |
| Offline support | **Có** | Không | Không |
| Rate limit | **Không** | 25,000/ngày (free) | 50,000/tháng (free) |

## 🎓 Kiến thức cần thiết

### Để sử dụng
- Biết chút Linux commands cơ bản
- Hiểu về Docker (docker-compose up, down, logs)
- Biết SSH để truy cập server

### Để customize
- JavaScript/TypeScript (cho frontend)
- React/Next.js (nếu muốn sửa UI)
- PostgreSQL/SQL (nếu muốn query trực tiếp database)
- Nginx config (nếu muốn custom reverse proxy)

### Để đóng góp
- Git/GitHub
- Docker & Docker Compose
- OSM data structure
- GIS concepts

## 🔐 Bảo mật

### Mặc định
- Rate limiting: 60 requests/phút cho routing và geocoding
- CORS enabled
- Không có authentication

### Production nên có
- [ ] API keys
- [ ] Authentication & Authorization
- [ ] HTTPS/SSL
- [ ] Firewall
- [ ] DDoS protection
- [ ] Regular backups
- [ ] Monitoring & alerts

## 💰 Chi phí vận hành

### VPS/Server
- **Basic** (cho test): ~$20-40/tháng
- **Production**: ~$80-150/tháng
- **High-traffic**: $200+/tháng

### Bandwidth
- Tiles: ~50KB/tile
- 1 triệu requests/tháng ≈ 50GB bandwidth
- Cần tính thêm traffic cho routing/geocoding

### Tổng cộng
- Startup nhỏ: ~$50-100/tháng
- Startup vừa: ~$200-500/tháng
- Enterprise: Custom

## 📈 Roadmap

### Phase 1 (Hiện tại) ✅
- [x] Basic tile server
- [x] Routing cho ô tô
- [x] Geocoding
- [x] Frontend demo
- [x] Documentation

### Phase 2 (Sắp tới)
- [ ] Routing cho xe máy
- [ ] Traffic data
- [ ] Real-time tracking
- [ ] POI search
- [ ] Mobile SDK

### Phase 3 (Tương lai)
- [ ] 3D buildings
- [ ] Indoor mapping
- [ ] Public transport routing
- [ ] AI-powered route suggestions

## 🤝 Cộng đồng

### Đóng góp
- Xem file `CONTRIBUTING.md`
- Tham gia [OpenStreetMap Vietnam](https://www.openstreetmap.org/)
- Cải thiện dữ liệu OSM cho Việt Nam

### Hỗ trợ
- Tạo [Issue](https://github.com/yourname/vietnam-map-server/issues)
- Pull Request
- Chia sẻ kinh nghiệm

## 📄 License

- **Code**: MIT License
- **OSM Data**: ODbL
- **Free** để sử dụng thương mại

## 🙏 Credits

Dự án này sử dụng:
- [OpenStreetMap](https://www.openstreetmap.org/) - Dữ liệu bản đồ
- [OSRM](http://project-osrm.org/) - Routing engine
- [Nominatim](https://nominatim.org/) - Geocoding
- [PostGIS](https://postgis.net/) - GIS database
- [MapLibre GL JS](https://maplibre.org/) - Map rendering
- [Geofabrik](https://www.geofabrik.de/) - OSM data hosting

---

**Made with ❤️ in Vietnam**

Nếu có câu hỏi, đọc `README.md`, `QUICKSTART.md`, hoặc các file trong thư mục `docs/`.
