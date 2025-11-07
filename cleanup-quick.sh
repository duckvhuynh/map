#!/bin/bash

#########################################
# Quick Cleanup - Xóa nhanh tất cả
# KHÔNG hỏi xác nhận - Dùng cẩn thận!
#########################################

echo "🗑️  Đang xóa tất cả containers..."
docker stop $(docker ps -a | grep -E 'map-|vietnam' | awk '{print $1}') 2>/dev/null || true
docker rm -f $(docker ps -a | grep -E 'map-|vietnam' | awk '{print $1}') 2>/dev/null || true

echo "🗑️  Đang xóa tất cả volumes..."
docker-compose down -v 2>/dev/null || docker compose down -v 2>/dev/null || true
docker volume rm -f $(docker volume ls -q | grep -E 'map|vietnam|postgres|nominatim|redis') 2>/dev/null || true

echo "🗑️  Đang xóa network..."
docker network rm $(docker network ls | grep -E 'mapnet|vietnam' | awk '{print $1}') 2>/dev/null || true

echo "🗑️  Đang xóa dữ liệu..."
rm -rf data/ docker/ .env 2>/dev/null || true

echo "🗑️  Đang xóa Nginx config..."
sudo rm -f /etc/nginx/sites-available/map.duckvhuynh.space 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/map.duckvhuynh.space 2>/dev/null || true
sudo rm -rf /var/cache/nginx/map_* 2>/dev/null || true
sudo systemctl reload nginx 2>/dev/null || true

echo "🧹 Đang dọn dẹp Docker..."
docker system prune -f 2>/dev/null || true

echo ""
echo "✅ HOÀN TẤT! Đã xóa tất cả."
echo ""
echo "Kiểm tra còn gì không:"
echo "  docker ps -a | grep map"
echo "  docker volume ls | grep map"
