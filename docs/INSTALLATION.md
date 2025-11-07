# Hướng dẫn Cài đặt Chi tiết - Vietnam Map Server

## Mục lục
1. [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
2. [Chuẩn bị môi trường](#chuẩn-bị-môi-trường)
3. [Cài đặt từng bước](#cài-đặt-từng-bước)
4. [Cấu hình](#cấu-hình)
5. [Xử lý lỗi](#xử-lý-lỗi)

## Yêu cầu hệ thống

### Phần cứng tối thiểu (Cho Việt Nam)
- **CPU**: 4 cores (Intel i5 hoặc tương đương)
- **RAM**: 8GB (16GB khuyến nghị)
- **Ổ cứng**: 50GB khả dụng (SSD khuyến nghị)
- **Băng thông**: 100Mbps

### Phần cứng khuyến nghị (Production)
- **CPU**: 8+ cores (Intel Xeon hoặc AMD EPYC)
- **RAM**: 32GB+
- **Ổ cứng**: 100GB+ SSD NVMe
- **Băng thông**: 1Gbps

### Hệ điều hành
- Ubuntu 20.04/22.04 LTS
- Debian 11/12
- CentOS/RHEL 8+
- Windows Server 2019+ (với WSL2)

## Chuẩn bị môi trường

### 1. Cập nhật hệ thống (Ubuntu/Debian)

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Cài đặt Docker

```bash
# Gỡ các phiên bản cũ
sudo apt remove docker docker-engine docker.io containerd runc

# Cài đặt các gói cần thiết
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Thêm Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Thêm Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Cài đặt Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Kiểm tra cài đặt
sudo docker --version
sudo docker compose version
```

### 3. Cấu hình Docker

```bash
# Thêm user vào group docker (không cần sudo)
sudo usermod -aG docker $USER
newgrp docker

# Khởi động Docker khi boot
sudo systemctl enable docker
sudo systemctl start docker

# Kiểm tra
docker ps
```

### 4. Tối ưu hệ thống cho PostgreSQL

```bash
# Tăng shared memory
sudo sysctl -w kernel.shmmax=17179869184
sudo sysctl -w kernel.shmall=4194304

# Tăng file descriptors
sudo sysctl -w fs.file-max=100000

# Lưu cấu hình
echo "kernel.shmmax=17179869184" | sudo tee -a /etc/sysctl.conf
echo "kernel.shmall=4194304" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=100000" | sudo tee -a /etc/sysctl.conf

# Áp dụng
sudo sysctl -p
```

## Cài đặt từng bước

### Bước 1: Clone hoặc tải project

```bash
# Nếu có git repository
git clone <your-repo-url> vietnam-map-server
cd vietnam-map-server

# Hoặc tạo thư mục mới và copy các file
mkdir vietnam-map-server
cd vietnam-map-server
```

### Bước 2: Cấu hình môi trường

```bash
# Copy file .env
cp .env.example .env

# Chỉnh sửa .env
nano .env
```

**Các cấu hình quan trọng trong .env:**

```bash
# Database - ĐỔI MẬT KHẨU!
POSTGRES_PASSWORD=your_strong_password_here

# Ports (nếu cần thay đổi)
NGINX_PORT=80
POSTGRES_PORT=5432

# Performance tuning (tùy theo RAM)
# Với 8GB RAM:
POSTGRES_SHARED_BUFFERS=2GB
POSTGRES_WORK_MEM=128MB
POSTGRES_MAINTENANCE_WORK_MEM=512MB

# Với 16GB RAM:
POSTGRES_SHARED_BUFFERS=4GB
POSTGRES_WORK_MEM=256MB
POSTGRES_MAINTENANCE_WORK_MEM=1GB

# Với 32GB+ RAM:
POSTGRES_SHARED_BUFFERS=8GB
POSTGRES_WORK_MEM=512MB
POSTGRES_MAINTENANCE_WORK_MEM=2GB
```

### Bước 3: Download dữ liệu OSM

```bash
# Tạo thư mục data
mkdir -p data/osm

# Download dữ liệu Việt Nam (khoảng 1.5GB)
cd data/osm
wget -c https://download.geofabrik.de/asia/vietnam-latest.osm.pbf

# Hoặc dùng script
cd ../..
bash scripts/download-vietnam-data.sh
```

**Lưu ý:** Download có thể mất 10-30 phút tùy vào tốc độ mạng.

### Bước 4: Khởi động PostgreSQL

```bash
# Khởi động PostgreSQL
docker compose up -d postgres

# Xem logs
docker compose logs -f postgres

# Chờ cho đến khi thấy "database system is ready to accept connections"
# Nhấn Ctrl+C để thoát logs
```

### Bước 5: Import dữ liệu OSM vào PostgreSQL

```bash
# Import OSM data (mất 30-60 phút)
docker compose run --rm import-osm

# Kiểm tra logs để theo dõi tiến trình
```

**Quá trình import sẽ:**
1. Đọc file OSM PBF
2. Parse và transform dữ liệu
3. Import vào PostgreSQL
4. Tạo indexes (chiếm phần lớn thời gian)

### Bước 6: Chuẩn bị dữ liệu routing

```bash
# Chuẩn bị routing data cho ô tô (mất 15-30 phút)
docker compose --profile import run --rm osrm-prepare-car

# Nếu cần routing cho xe đạp
docker compose --profile import run --rm osrm-prepare-bike

# Nếu cần routing cho đi bộ
docker compose --profile import run --rm osrm-prepare-foot
```

### Bước 7: Khởi động tất cả services

```bash
# Khởi động tất cả
docker compose up -d

# Xem logs
docker compose logs -f

# Kiểm tra trạng thái
docker compose ps
```

**Tất cả services nên ở trạng thái "Up":**
- postgres
- tileserver
- osrm-car
- nominatim
- martin
- frontend
- nginx

### Bước 8: Kiểm tra services

```bash
# Health checks
curl http://localhost/health
curl http://localhost:8080/health
curl http://localhost:5000/health

# Test geocoding
curl "http://localhost/geocode/search?q=Hanoi&format=json"

# Test routing
curl "http://localhost/route/v1/driving/105.8342,21.0278;106.6297,10.8231"
```

## Cấu hình

### Cấu hình Nginx cho Production

Nếu deploy trên server thật với domain:

```bash
# Chỉnh sửa .env
nano .env

# Thêm/sửa các dòng:
SSL_ENABLED=true
SSL_DOMAIN=yourdomain.com
SSL_EMAIL=your-email@example.com
```

Sau đó chạy:

```bash
bash scripts/setup-ssl.sh yourdomain.com
```

### Cấu hình Firewall

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Hoặc iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### Cấu hình Backup tự động

```bash
# Tạo cron job
crontab -e

# Thêm dòng này (backup mỗi ngày lúc 2h sáng)
0 2 * * * /path/to/vietnam-map-server/scripts/backup.sh

# Backup hàng tuần
0 2 * * 0 /path/to/vietnam-map-server/scripts/backup.sh
```

## Xử lý lỗi

### Lỗi: "Cannot connect to Docker daemon"

```bash
# Khởi động Docker
sudo systemctl start docker

# Kiểm tra status
sudo systemctl status docker
```

### Lỗi: "Port already in use"

```bash
# Kiểm tra port đang dùng
sudo lsof -i :80
sudo lsof -i :5432

# Kill process nếu cần
sudo kill -9 <PID>

# Hoặc đổi port trong .env
NGINX_PORT=8080
POSTGRES_PORT=5433
```

### Lỗi: "Out of memory" khi import

```bash
# Tạo swap space
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Lưu vĩnh viễn
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Giảm RAM cho PostgreSQL trong .env
POSTGRES_SHARED_BUFFERS=1GB
POSTGRES_WORK_MEM=128MB
```

### Lỗi: Import OSM thất bại

```bash
# Xóa dữ liệu cũ
docker compose down -v

# Xóa cache
sudo rm -rf data/routing/*
docker volume prune -f

# Khởi động lại PostgreSQL
docker compose up -d postgres
sleep 10

# Import lại
docker compose run --rm import-osm
```

### Lỗi: Nominatim không khởi động

```bash
# Tăng shared memory
docker compose down
docker compose up -d nominatim

# Xem logs chi tiết
docker compose logs nominatim

# Nếu cần import lại
docker compose --profile import run --rm import-nominatim
```

### Lỗi: Frontend không hiển thị bản đồ

```bash
# Rebuild frontend
docker compose down frontend
docker compose up -d --build frontend

# Xóa cache browser (Ctrl+Shift+R)

# Kiểm tra logs
docker compose logs frontend
```

## Bước tiếp theo

Sau khi cài đặt thành công:

1. **Truy cập ứng dụng**: http://your-server-ip hoặc http://localhost
2. **Xem tài liệu API**: Đọc file `docs/API.md`
3. **Cấu hình monitoring**: Theo dõi hiệu suất hệ thống
4. **Backup định kỳ**: Đảm bảo dữ liệu an toàn

## Hỗ trợ

Nếu gặp vấn đề:

1. Kiểm tra logs: `docker compose logs -f [service-name]`
2. Xem file README.md
3. Tạo issue trên GitHub
4. Tham gia cộng đồng OpenStreetMap Vietnam
