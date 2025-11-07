#!/bin/bash

#########################################
# Vietnam Map Server - Complete Cleanup
# Xóa toàn bộ containers, volumes, networks
# VÀ data đã tải về
#########################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo ""
print_warning "========================================="
print_warning "⚠️  VIETNAM MAP SERVER - CLEANUP ⚠️"
print_warning "========================================="
echo ""
print_error "Script này sẽ XÓA HOÀN TOÀN:"
echo "  ❌ Tất cả Docker containers"
echo "  ❌ Tất cả Docker volumes (database, cache)"
echo "  ❌ Tất cả dữ liệu OSM đã tải"
echo "  ❌ Tất cả file config"
echo "  ❌ Nginx configuration (nếu có)"
echo ""
print_warning "⚠️  CẢNH BÁO: Hành động này KHÔNG THỂ HOÀN TÁC!"
echo ""

# Confirm
read -p "Bạn có CHẮC CHẮN muốn xóa tất cả? (nhập 'YES' để xác nhận): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    print_status "Đã hủy. Không có gì bị xóa."
    exit 0
fi

echo ""
print_warning "Xác nhận lần 2..."
read -p "Thực sự xóa HẾT? (nhập 'DELETE' để xác nhận): " CONFIRM2

if [ "$CONFIRM2" != "DELETE" ]; then
    print_status "Đã hủy. Không có gì bị xóa."
    exit 0
fi

echo ""
print_status "========================================="
print_status "Bắt đầu dọn dẹp..."
print_status "========================================="
echo ""

# Get project directory
if [ -d "$HOME/map" ]; then
    PROJECT_DIR="$HOME/map"
elif [ -d "$HOME/vietnam-map-server" ]; then
    PROJECT_DIR="$HOME/vietnam-map-server"
else
    PROJECT_DIR=$(pwd)
fi

print_status "Project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Check if using docker-compose or docker compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

#########################################
# 1. Stop all containers
#########################################
print_status ""
print_status "Step 1: Dừng tất cả containers..."

if [ -f "docker-compose.yml" ]; then
    $DOCKER_COMPOSE down --remove-orphans || true
    print_success "Đã dừng containers từ docker-compose"
else
    print_warning "Không tìm thấy docker-compose.yml"
fi

# Stop individual containers nếu còn
for container in $(docker ps -a | grep -E 'map-|vietnam-map' | awk '{print $1}'); do
    print_status "Dừng container: $container"
    docker stop $container || true
done

print_success "Đã dừng tất cả containers"
echo ""

#########################################
# 2. Remove all containers
#########################################
print_status "Step 2: Xóa tất cả containers..."

for container in $(docker ps -a | grep -E 'map-|vietnam-map' | awk '{print $1}'); do
    print_status "Xóa container: $container"
    docker rm -f $container || true
done

print_success "Đã xóa tất cả containers"
echo ""

#########################################
# 3. Remove all volumes
#########################################
print_status "Step 3: Xóa tất cả volumes..."

print_warning "⚠️  Đang xóa DATABASE và tất cả dữ liệu đã import..."

if [ -f "docker-compose.yml" ]; then
    $DOCKER_COMPOSE down -v || true
fi

# Remove named volumes
for volume in $(docker volume ls -q | grep -E 'map|vietnam|postgres|nominatim|redis'); do
    print_status "Xóa volume: $volume"
    docker volume rm -f $volume || true
done

print_success "Đã xóa tất cả volumes"
echo ""

#########################################
# 4. Remove custom network
#########################################
print_status "Step 4: Xóa network..."

for network in $(docker network ls | grep -E 'mapnet|vietnam' | awk '{print $1}'); do
    print_status "Xóa network: $network"
    docker network rm $network || true
done

print_success "Đã xóa network"
echo ""

#########################################
# 5. Remove downloaded data
#########################################
print_status "Step 5: Xóa dữ liệu OSM đã tải..."

if [ -d "data" ]; then
    print_warning "Xóa thư mục data/..."
    rm -rf data/
    print_success "Đã xóa thư mục data/"
fi

print_success "Đã xóa dữ liệu OSM"
echo ""

#########################################
# 6. Remove Docker configs
#########################################
print_status "Step 6: Xóa các file config..."

if [ -d "docker" ]; then
    print_warning "Xóa thư mục docker/..."
    rm -rf docker/
    print_success "Đã xóa thư mục docker/"
fi

print_success "Đã xóa config files"
echo ""

#########################################
# 7. Remove Nginx config (if exists)
#########################################
print_status "Step 7: Xóa Nginx config (nếu có)..."

NGINX_CONFIG="/etc/nginx/sites-available/map.duckvhuynh.space"
NGINX_ENABLED="/etc/nginx/sites-enabled/map.duckvhuynh.space"

if [ -f "$NGINX_CONFIG" ]; then
    print_status "Xóa Nginx config..."
    sudo rm -f "$NGINX_CONFIG" || true
    print_success "Đã xóa $NGINX_CONFIG"
fi

if [ -L "$NGINX_ENABLED" ]; then
    print_status "Xóa Nginx symlink..."
    sudo rm -f "$NGINX_ENABLED" || true
    print_success "Đã xóa $NGINX_ENABLED"
fi

# Remove Nginx cache
if [ -d "/var/cache/nginx/map_tiles" ]; then
    print_status "Xóa Nginx cache..."
    sudo rm -rf /var/cache/nginx/map_tiles /var/cache/nginx/map_api || true
    print_success "Đã xóa Nginx cache"
fi

# Reload Nginx if running
if systemctl is-active --quiet nginx; then
    print_status "Reload Nginx..."
    sudo systemctl reload nginx || true
    print_success "Đã reload Nginx"
fi

echo ""

#########################################
# 8. Clean Docker system
#########################################
print_status "Step 8: Dọn dẹp Docker system..."

print_status "Xóa unused images..."
docker image prune -f || true

print_status "Xóa unused containers..."
docker container prune -f || true

print_status "Xóa unused volumes..."
docker volume prune -f || true

print_status "Xóa unused networks..."
docker network prune -f || true

print_success "Đã dọn dẹp Docker system"
echo ""

#########################################
# 9. Remove environment files
#########################################
print_status "Step 9: Xóa environment files..."

if [ -f ".env" ]; then
    print_warning "Xóa .env file..."
    rm -f .env
    print_success "Đã xóa .env"
fi

echo ""

#########################################
# 10. Verify cleanup
#########################################
print_status "Step 10: Kiểm tra kết quả..."
echo ""

# Check containers
CONTAINER_COUNT=$(docker ps -a | grep -cE 'map-|vietnam-map' || echo "0")
print_status "Containers còn lại: $CONTAINER_COUNT"

# Check volumes
VOLUME_COUNT=$(docker volume ls -q | grep -cE 'map|vietnam|postgres|nominatim' || echo "0")
print_status "Volumes còn lại: $VOLUME_COUNT"

# Check data directory
if [ -d "data" ]; then
    print_warning "⚠️  Thư mục data/ vẫn còn"
else
    print_success "✓ Thư mục data/ đã xóa"
fi

# Check docker directory
if [ -d "docker" ]; then
    print_warning "⚠️  Thư mục docker/ vẫn còn"
else
    print_success "✓ Thư mục docker/ đã xóa"
fi

# Check nginx config
if [ -f "$NGINX_CONFIG" ]; then
    print_warning "⚠️  Nginx config vẫn còn"
else
    print_success "✓ Nginx config đã xóa"
fi

echo ""

#########################################
# Summary
#########################################
print_status "========================================="
print_success "✅ DỌN DẸP HOÀN TẤT!"
print_status "========================================="
echo ""
print_status "Đã xóa:"
echo "  ✓ Tất cả Docker containers"
echo "  ✓ Tất cả Docker volumes (database, cache)"
echo "  ✓ Tất cả dữ liệu OSM"
echo "  ✓ Tất cả file config"
echo "  ✓ Nginx configuration"
echo ""

if [ "$CONTAINER_COUNT" -eq 0 ] && [ "$VOLUME_COUNT" -eq 0 ]; then
    print_success "🎉 Hệ thống đã sạch hoàn toàn!"
else
    print_warning "⚠️  Vẫn còn một số tài nguyên, có thể cần xóa thủ công:"
    
    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        echo ""
        print_warning "Containers còn lại:"
        docker ps -a | grep -E 'map-|vietnam-map'
    fi
    
    if [ "$VOLUME_COUNT" -gt 0 ]; then
        echo ""
        print_warning "Volumes còn lại:"
        docker volume ls | grep -E 'map|vietnam|postgres|nominatim'
    fi
fi

echo ""
print_status "Nếu muốn xóa TOÀN BỘ Docker (bao gồm cả các project khác):"
echo "  docker system prune -a --volumes"
echo ""
print_status "Nếu muốn xóa cả repository:"
echo "  cd ~ && rm -rf $PROJECT_DIR"
echo ""
print_status "========================================="
