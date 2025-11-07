# 🗑️ Hướng Dẫn Dọn Dẹp & Xóa Bỏ Hoàn Toàn

Hướng dẫn xóa hoàn toàn Vietnam Map Server khỏi VPS.

## ⚠️ CẢNH BÁO

**Các script này sẽ XÓA HOÀN TOÀN:**
- ❌ Tất cả Docker containers
- ❌ Tất cả Docker volumes (DATABASE, CACHE)
- ❌ Tất cả dữ liệu OSM đã tải (~1.5GB)
- ❌ Tất cả OSRM routing data
- ❌ Tất cả file config
- ❌ Nginx configuration (nếu có)

**⚠️ KHÔNG THỂ HOÀN TÁC! BACKUP trước khi chạy!**

---

## 🚀 Cách 1: Cleanup Script An Toàn (Khuyến Nghị)

Script này sẽ hỏi xác nhận 2 lần trước khi xóa.

```bash
# Trên VPS
cd ~/map

# Chạy script cleanup
bash cleanup.sh
```

Script sẽ hỏi xác nhận:
1. Nhập `YES` để xác nhận lần 1
2. Nhập `DELETE` để xác nhận lần 2

Sau đó script sẽ:
- ✓ Dừng tất cả containers
- ✓ Xóa containers
- ✓ Xóa volumes (database)
- ✓ Xóa networks
- ✓ Xóa dữ liệu OSM
- ✓ Xóa config files
- ✓ Xóa Nginx config
- ✓ Dọn dẹp Docker system
- ✓ Báo cáo kết quả

---

## ⚡ Cách 2: Quick Cleanup (Xóa Nhanh)

**KHÔNG hỏi xác nhận** - Xóa ngay lập tức!

```bash
# Trên VPS
cd ~/map

# Chạy quick cleanup
bash cleanup-quick.sh
```

**Dùng cẩn thận!** Script này xóa ngay không hỏi.

---

## 🛠️ Cách 3: Xóa Thủ Công Từng Bước

### Bước 1: Dừng & Xóa Containers

```bash
# Dừng tất cả containers
docker-compose down

# Hoặc dừng từng container
docker stop map-postgres map-frontend map-tileserver map-osrm-car map-nominatim map-martin

# Xóa containers
docker rm -f map-postgres map-frontend map-tileserver map-osrm-car map-nominatim map-martin
```

### Bước 2: Xóa Volumes (Database)

**⚠️ Cẩn thận: Xóa hết database!**

```bash
# Xóa với docker-compose
docker-compose down -v

# Hoặc xóa thủ công
docker volume rm map_postgres_data map_nominatim_data map_redis_data
```

### Bước 3: Xóa Network

```bash
docker network rm map_mapnet
```

### Bước 4: Xóa Dữ Liệu OSM

```bash
cd ~/map
rm -rf data/
```

### Bước 5: Xóa Config Files

```bash
cd ~/map
rm -rf docker/
rm -f .env
```

### Bước 6: Xóa Nginx Config (nếu dùng Nginx)

```bash
# Xóa config files
sudo rm -f /etc/nginx/sites-available/map.duckvhuynh.space
sudo rm -f /etc/nginx/sites-enabled/map.duckvhuynh.space

# Xóa cache
sudo rm -rf /var/cache/nginx/map_tiles
sudo rm -rf /var/cache/nginx/map_api

# Reload Nginx
sudo systemctl reload nginx
```

### Bước 7: Dọn Dẹp Docker

```bash
# Xóa unused images
docker image prune -f

# Xóa unused volumes
docker volume prune -f

# Xóa unused networks
docker network prune -f

# Xóa unused containers
docker container prune -f
```

### Bước 8: Xóa Repository (Tùy Chọn)

```bash
# Xóa toàn bộ thư mục project
cd ~
rm -rf map/
```

---

## 🔍 Kiểm Tra Sau Khi Xóa

### Kiểm tra containers còn lại

```bash
docker ps -a | grep map
```

Kết quả mong đợi: Không có gì

### Kiểm tra volumes còn lại

```bash
docker volume ls | grep map
```

Kết quả mong đợi: Không có gì

### Kiểm tra networks còn lại

```bash
docker network ls | grep map
```

Kết quả mong đợi: Không có gì

### Kiểm tra dung lượng đã giải phóng

```bash
df -h
```

### Kiểm tra thư mục

```bash
ls -lh ~/map/data/
```

Kết quả mong đợi: "No such file or directory"

---

## 🧹 Dọn Dẹp Hoàn Toàn Docker (Tất Cả Projects)

**⚠️ CẢNH BÁO: Xóa TẤT CẢ containers, images, volumes của TOÀN BỘ Docker!**

```bash
# Dừng tất cả containers
docker stop $(docker ps -aq)

# Xóa tất cả
docker system prune -a --volumes

# Xác nhận với 'y'
```

Lệnh này sẽ xóa:
- Tất cả containers (đang dừng)
- Tất cả images
- Tất cả volumes
- Tất cả networks (unused)
- Tất cả build cache

---

## 📊 Ước Tính Dung Lượng Giải Phóng

Sau khi cleanup hoàn toàn:

- **OSM Data**: ~1.5GB
- **PostgreSQL Database**: ~3-5GB
- **OSRM Routing Data**: ~2-3GB (car+bike+foot)
- **Nominatim Data**: ~1-2GB
- **Docker Images**: ~2-3GB
- **Build Cache**: ~500MB

**Tổng cộng: ~10-15GB** được giải phóng

---

## ✅ Checklist Sau Cleanup

- [ ] Không còn containers: `docker ps -a | grep map`
- [ ] Không còn volumes: `docker volume ls | grep map`
- [ ] Không còn networks: `docker network ls | grep map`
- [ ] Không còn thư mục data: `ls ~/map/data`
- [ ] Nginx config đã xóa: `ls /etc/nginx/sites-available/map*`
- [ ] Domain không còn hoạt động: `curl https://map.duckvhuynh.space`

---

## 🔄 Nếu Muốn Deploy Lại

### Option 1: Deploy lại từ đầu

```bash
cd ~
git clone https://github.com/duckvhuynh/map.git
cd map
bash deploy.sh
```

### Option 2: Deploy với Coolify

Làm theo hướng dẫn trong [COOLIFY_DEPLOY.md](./COOLIFY_DEPLOY.md)

---

## 🆘 Troubleshooting

### Container không chịu dừng

```bash
# Force kill
docker kill map-postgres map-frontend map-tileserver
```

### Volume không thể xóa (đang được sử dụng)

```bash
# Tìm container đang dùng
docker ps -a --filter volume=map_postgres_data

# Dừng container đó
docker stop <container_id>

# Xóa volume
docker volume rm map_postgres_data
```

### Permission denied khi xóa files

```bash
# Dùng sudo
sudo rm -rf ~/map/data/
sudo rm -rf /var/cache/nginx/map_*
```

### Nginx vẫn trỏ đến map.duckvhuynh.space

```bash
# Kiểm tra config
sudo nginx -t

# Nếu có lỗi, xóa config
sudo rm -f /etc/nginx/sites-enabled/map.duckvhuynh.space
sudo systemctl reload nginx
```

### Docker disk usage vẫn cao

```bash
# Kiểm tra disk usage
docker system df

# Cleanup toàn bộ (cẩn thận!)
docker system prune -a --volumes
```

---

## 📝 Notes

- **Backup quan trọng**: Nếu có data quan trọng, backup trước:
  ```bash
  docker exec map-postgres pg_dump -U mapuser mapdb > backup.sql
  ```

- **Coolify**: Nếu deploy qua Coolify, xóa application trong Coolify dashboard trước

- **DNS**: Nếu có DNS record cho map.duckvhuynh.space, xóa/vô hiệu hóa nó

- **SSL Certificate**: Let's Encrypt cert sẽ tự expire sau 90 ngày

---

## 💡 Tips

1. **Chạy cleanup.sh an toàn hơn** - có xác nhận 2 lần
2. **Backup database trước** nếu cần giữ lại data
3. **Kiểm tra kỹ** sau cleanup xem còn gì không
4. **Dọn dẹp Coolify** nếu deploy qua Coolify
5. **Xóa DNS record** nếu không dùng subdomain nữa

---

**Made with ❤️ for Vietnam**
