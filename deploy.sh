#!/bin/bash

#########################################
# Vietnam Map Server - Deploy Script
# Domain: map.duckvhuynh.space
# Server: VPS với Nginx + SSL sẵn có
#########################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="map.duckvhuynh.space"
PROJECT_DIR="$HOME/vietnam-map-server"
NGINX_CONFIG="/etc/nginx/sites-available/map.duckvhuynh.space"
NGINX_ENABLED="/etc/nginx/sites-enabled/map.duckvhuynh.space"

# Helper functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 chưa được cài đặt"
        return 1
    fi
    print_success "$1 đã sẵn sàng"
    return 0
}

#########################################
# 1. Kiểm tra requirements
#########################################
print_status "========================================="
print_status "BƯỚC 1: Kiểm tra requirements"
print_status "========================================="

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_error "Script này chỉ chạy trên Linux"
    exit 1
fi

# Check commands
check_command docker || exit 1
check_command docker-compose || check_command "docker compose" || exit 1
check_command nginx || exit 1
check_command wget || check_command curl || exit 1

# Check if running as root for nginx config
if [ "$EUID" -ne 0 ]; then 
    print_warning "Script cần sudo để config Nginx"
    print_status "Sẽ yêu cầu sudo khi cần thiết..."
fi

# Check disk space (cần ít nhất 30GB trống)
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 30 ]; then
    print_error "Không đủ dung lượng ổ cứng. Cần ít nhất 30GB, còn ${AVAILABLE_SPACE}GB"
    exit 1
fi
print_success "Dung lượng ổ cứng: ${AVAILABLE_SPACE}GB"

# Check RAM (khuyến nghị ít nhất 8GB)
TOTAL_RAM=$(free -g | awk 'NR==2 {print $2}')
if [ "$TOTAL_RAM" -lt 7 ]; then
    print_warning "RAM thấp (${TOTAL_RAM}GB). Khuyến nghị ít nhất 8GB"
    read -p "Tiếp tục? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
print_success "RAM: ${TOTAL_RAM}GB"

#########################################
# 2. Setup environment
#########################################
print_status ""
print_status "========================================="
print_status "BƯỚC 2: Setup environment"
print_status "========================================="

# Navigate to project directory
cd "$(dirname "$0")"
PROJECT_DIR=$(pwd)
print_status "Project directory: $PROJECT_DIR"

# Create .env if not exists
if [ ! -f .env ]; then
    print_status "Tạo file .env..."
    cp .env.example .env
    
    # Generate random password
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
    
    # Set domain
    sed -i "s/DOMAIN=.*/DOMAIN=$DOMAIN/" .env
    
    print_success "Đã tạo .env với password ngẫu nhiên"
else
    print_success ".env đã tồn tại"
fi

# Create data directories
print_status "Tạo thư mục dữ liệu..."
mkdir -p data/osm data/tiles data/routing/{car,bike,foot}
print_success "Đã tạo thư mục dữ liệu"

#########################################
# 3. Download Vietnam OSM data
#########################################
print_status ""
print_status "========================================="
print_status "BƯỚC 3: Download dữ liệu Việt Nam"
print_status "========================================="

OSM_FILE="data/osm/vietnam-latest.osm.pbf"
OSM_URL="https://download.geofabrik.de/asia/vietnam-latest.osm.pbf"

if [ -f "$OSM_FILE" ]; then
    FILE_SIZE=$(du -h "$OSM_FILE" | cut -f1)
    print_warning "File OSM đã tồn tại: $OSM_FILE ($FILE_SIZE)"
    read -p "Download lại? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$OSM_FILE"
    else
        print_status "Sử dụng file OSM hiện có"
    fi
fi

if [ ! -f "$OSM_FILE" ]; then
    print_status "Downloading Vietnam OSM data (~1.5GB)..."
    print_status "Source: $OSM_URL"
    
    if command -v wget &> /dev/null; then
        wget -c -O "$OSM_FILE" "$OSM_URL" || {
            print_error "Download thất bại"
            exit 1
        }
    else
        curl -L -C - -o "$OSM_FILE" "$OSM_URL" || {
            print_error "Download thất bại"
            exit 1
        }
    fi
    
    FILE_SIZE=$(du -h "$OSM_FILE" | cut -f1)
    print_success "Download hoàn tất: $FILE_SIZE"
fi

#########################################
# 4. Start PostgreSQL và import data
#########################################
print_status ""
print_status "========================================="
print_status "BƯỚC 4: Import dữ liệu vào PostgreSQL"
print_status "========================================="

# Check if using docker-compose or docker compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

print_status "Khởi động PostgreSQL..."
$DOCKER_COMPOSE up -d postgres

print_status "Đợi PostgreSQL khởi động (15 giây)..."
sleep 15

# Check if data already imported
TABLES_COUNT=$($DOCKER_COMPOSE exec -T postgres psql -U mapuser -d mapdb -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='osm'" 2>/dev/null || echo "0")

if [ "$TABLES_COUNT" -gt 5 ]; then
    print_warning "Database đã có dữ liệu ($TABLES_COUNT tables)"
    read -p "Import lại? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Bỏ qua import"
    else
        print_status "Importing OSM data (30-60 phút)..."
        $DOCKER_COMPOSE run --rm import-osm
        print_success "Import hoàn tất"
    fi
else
    print_status "Importing OSM data (30-60 phút)..."
    print_warning "Quá trình này có thể mất thời gian, vui lòng đợi..."
    $DOCKER_COMPOSE run --rm import-osm
    print_success "Import hoàn tất"
fi

#########################################
# 5. Prepare routing data
#########################################
print_status ""
print_status "========================================="
print_status "BƯỚC 5: Chuẩn bị routing data"
print_status "========================================="

prepare_routing() {
    local profile=$1
    local file="data/routing/$profile/vietnam-latest.osrm"
    
    if [ -f "$file" ]; then
        print_warning "Routing data cho $profile đã tồn tại"
        return 0
    fi
    
    print_status "Preparing routing for $profile (10-20 phút)..."
    $DOCKER_COMPOSE --profile import run --rm osrm-prepare-$profile
    print_success "Routing $profile hoàn tất"
}

prepare_routing "car"
prepare_routing "bike"
prepare_routing "foot"

#########################################
# 6. Config Nginx reverse proxy
#########################################
print_status ""
print_status "========================================="
print_status "BƯỚC 6: Cấu hình Nginx"
print_status "========================================="

print_status "Tạo Nginx config cho $DOMAIN..."

sudo tee "$NGINX_CONFIG" > /dev/null <<'NGINX_EOF'
# Vietnam Map Server - Nginx Configuration
# Domain: map.duckvhuynh.space

upstream map_frontend {
    server localhost:3001;
}

upstream map_tileserver {
    server localhost:8080;
}

upstream map_nominatim {
    server localhost:7070;
}

upstream map_osrm_car {
    server localhost:5000;
}

upstream map_osrm_bike {
    server localhost:5001;
}

upstream map_osrm_foot {
    server localhost:5002;
}

upstream map_martin {
    server localhost:3000;
}

# Cache configuration
proxy_cache_path /var/cache/nginx/map_tiles levels=1:2 keys_zone=map_tiles:100m max_size=10g inactive=7d use_temp_path=off;
proxy_cache_path /var/cache/nginx/map_api levels=1:2 keys_zone=map_api:10m max_size=1g inactive=1h use_temp_path=off;

# Rate limiting
limit_req_zone $binary_remote_addr zone=map_geocode:10m rate=60r/m;
limit_req_zone $binary_remote_addr zone=map_route:10m rate=120r/m;

server {
    listen 80;
    server_name map.duckvhuynh.space;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name map.duckvhuynh.space;

    # SSL Configuration (sử dụng cert có sẵn của duckvhuynh.space)
    ssl_certificate /etc/letsencrypt/live/duckvhuynh.space/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/duckvhuynh.space/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Logs
    access_log /var/log/nginx/map.duckvhuynh.space.access.log;
    error_log /var/log/nginx/map.duckvhuynh.space.error.log warn;

    # Max body size
    client_max_body_size 10M;

    # Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    # Frontend
    location / {
        proxy_pass http://map_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Tiles - Raster (with heavy caching)
    location /tiles/ {
        proxy_pass http://map_tileserver/styles/osm-bright/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        
        # Caching
        proxy_cache map_tiles;
        proxy_cache_valid 200 7d;
        proxy_cache_valid 404 1h;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_cache_lock on;
        add_header X-Cache-Status $upstream_cache_status;
        
        # CORS
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods 'GET, OPTIONS';
        
        expires 7d;
    }

    # Vector Tiles
    location /vector/ {
        proxy_pass http://map_martin/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        
        # Caching
        proxy_cache map_tiles;
        proxy_cache_valid 200 7d;
        proxy_cache_valid 404 1h;
        add_header X-Cache-Status $upstream_cache_status;
        
        # CORS
        add_header Access-Control-Allow-Origin *;
        
        expires 7d;
    }

    # Geocoding API
    location /geocode {
        limit_req zone=map_geocode burst=10 nodelay;
        
        proxy_pass http://map_nominatim/search;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # Light caching
        proxy_cache map_api;
        proxy_cache_valid 200 1h;
        proxy_cache_key "$scheme$request_method$host$request_uri$args";
        add_header X-Cache-Status $upstream_cache_status;
        
        # CORS
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
    }

    # Reverse Geocoding
    location /reverse {
        limit_req zone=map_geocode burst=10 nodelay;
        
        proxy_pass http://map_nominatim/reverse;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        
        proxy_cache map_api;
        proxy_cache_valid 200 1h;
        add_header X-Cache-Status $upstream_cache_status;
        
        add_header Access-Control-Allow-Origin *;
    }

    # Routing - Car
    location /route/car/ {
        limit_req zone=map_route burst=20 nodelay;
        
        rewrite ^/route/car/(.*)$ /$1 break;
        proxy_pass http://map_osrm_car;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        
        add_header Access-Control-Allow-Origin *;
    }

    # Routing - Bike
    location /route/bike/ {
        limit_req zone=map_route burst=20 nodelay;
        
        rewrite ^/route/bike/(.*)$ /$1 break;
        proxy_pass http://map_osrm_bike;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        
        add_header Access-Control-Allow-Origin *;
    }

    # Routing - Foot
    location /route/foot/ {
        limit_req zone=map_route burst=20 nodelay;
        
        rewrite ^/route/foot/(.*)$ /$1 break;
        proxy_pass http://map_osrm_foot;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        
        add_header Access-Control-Allow-Origin *;
    }

    # Default routing (car)
    location /route {
        limit_req zone=map_route burst=20 nodelay;
        
        proxy_pass http://map_osrm_car;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        
        add_header Access-Control-Allow-Origin *;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF

print_success "Đã tạo Nginx config"

# Create cache directories
print_status "Tạo thư mục cache..."
sudo mkdir -p /var/cache/nginx/map_tiles /var/cache/nginx/map_api
sudo chown -R www-data:www-data /var/cache/nginx/map_tiles /var/cache/nginx/map_api

# Enable site
if [ -L "$NGINX_ENABLED" ]; then
    print_warning "Site đã được enable"
else
    print_status "Enable site..."
    sudo ln -s "$NGINX_CONFIG" "$NGINX_ENABLED"
fi

# Test nginx config
print_status "Test Nginx config..."
sudo nginx -t || {
    print_error "Nginx config có lỗi"
    exit 1
}

print_success "Nginx config hợp lệ"

#########################################
# 7. Update frontend API URLs
#########################################
print_status ""
print_status "========================================="
print_status "BƯỚC 7: Update frontend config"
print_status "========================================="

# Update .env to use domain
if ! grep -q "NEXT_PUBLIC_API_URL" .env; then
    echo "" >> .env
    echo "# Frontend API URL" >> .env
    echo "NEXT_PUBLIC_API_URL=https://$DOMAIN" >> .env
    print_success "Đã thêm NEXT_PUBLIC_API_URL vào .env"
fi

#########################################
# 8. Start all services
#########################################
print_status ""
print_status "========================================="
print_status "BƯỚC 8: Khởi động tất cả services"
print_status "========================================="

print_status "Building và starting containers..."
$DOCKER_COMPOSE up -d --build

print_status "Đợi services khởi động (30 giây)..."
sleep 30

# Check service health
print_status "Kiểm tra trạng thái services..."
$DOCKER_COMPOSE ps

#########################################
# 9. Reload Nginx
#########################################
print_status ""
print_status "========================================="
print_status "BƯỚC 9: Reload Nginx"
print_status "========================================="

sudo systemctl reload nginx
print_success "Nginx đã reload"

#########################################
# 10. Final checks
#########################################
print_status ""
print_status "========================================="
print_status "BƯỚC 10: Kiểm tra cuối cùng"
print_status "========================================="

# Wait a bit for services to stabilize
sleep 10

print_status "Kiểm tra endpoints..."

check_endpoint() {
    local url=$1
    local name=$2
    
    if curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" | grep -q "200\|301\|302"; then
        print_success "$name: OK"
    else
        print_warning "$name: Không phản hồi (có thể cần thời gian khởi động)"
    fi
}

check_endpoint "http://localhost:3001" "Frontend"
check_endpoint "http://localhost:8080" "TileServer"
check_endpoint "http://localhost:7070" "Nominatim"
check_endpoint "http://localhost:5000" "OSRM Car"
check_endpoint "http://localhost:3000" "Martin"

#########################################
# Done!
#########################################
print_status ""
print_status "========================================="
print_success "🎉 DEPLOY HOÀN TẤT! 🎉"
print_status "========================================="
echo ""
print_status "Truy cập bản đồ tại:"
echo -e "${GREEN}https://map.duckvhuynh.space${NC}"
echo ""
print_status "Các API endpoints:"
echo "  - Geocoding:  https://map.duckvhuynh.space/geocode?q=Hanoi"
echo "  - Reverse:    https://map.duckvhuynh.space/reverse?lat=21.028&lon=105.854"
echo "  - Routing:    https://map.duckvhuynh.space/route/v1/driving/105.8,21.0;106.7,20.8"
echo "  - Tiles:      https://map.duckvhuynh.space/tiles/{z}/{x}/{y}.png"
echo ""
print_status "Quản lý services:"
echo "  - Xem logs:     cd $PROJECT_DIR && docker-compose logs -f"
echo "  - Restart:      cd $PROJECT_DIR && docker-compose restart"
echo "  - Stop:         cd $PROJECT_DIR && docker-compose down"
echo "  - Backup DB:    cd $PROJECT_DIR && bash scripts/backup.sh"
echo ""
print_warning "Lưu ý:"
echo "  - Lần đầu load tiles có thể chậm (đang generate)"
echo "  - Nominatim cần ~5-10 phút để index xong"
echo "  - Nếu có lỗi, check logs: docker-compose logs [service-name]"
echo ""
print_success "Deployment script by Vietnam Map Server"
print_status "========================================="
