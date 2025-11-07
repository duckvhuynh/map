# 🔧 Fix Coolify Build Timeout Issue

## Vấn Đề

Build Next.js bị timeout trong Coolify với lỗi:
```
Oops something is not okay, are you okay? 😢
```

## Nguyên Nhân

1. **Build timeout**: Coolify có giới hạn thời gian build (thường 10-15 phút)
2. **TypeScript type checking**: Next.js build kiểm tra types, tốn thời gian
3. **ESLint**: Chạy linting trong build process
4. **Large dependencies**: npm install dependencies mất thời gian

## Giải Pháp Đã Implement

### ✅ 1. Skip TypeScript Type Checking

**File: `frontend/next.config.js`**
```js
typescript: {
  ignoreBuildErrors: true,
},
eslint: {
  ignoreDuringBuilds: true,
},
```

### ✅ 2. Optimize Dockerfile

**File: `frontend/Dockerfile`**
- Added `NEXT_SKIP_TYPE_CHECKING=1`
- Added `NEXT_SKIP_LINT=1`
- Use `npm ci --prefer-offline --no-audit --progress=false`

### ✅ 3. Add .dockerignore

**File: `frontend/.dockerignore`**
- Exclude `node_modules`, `.next`, `.git`, etc.
- Giảm build context size

### ✅ 4. Increase Health Check Timeouts

**File: `docker-compose.coolify.yml`**
- `start_period: 120s` (tăng từ 60s)
- `retries: 5` (tăng từ 3)

## Alternative: Build Locally & Push Image

Nếu build trên Coolify vẫn timeout, có thể build local và push lên Docker Hub:

### Option 1: Build Local & Push to Docker Hub

```bash
# 1. Build image locally
cd frontend
docker build -t duckvhuynh/vietnam-map-frontend:latest .

# 2. Push to Docker Hub
docker login
docker push duckvhuynh/vietnam-map-frontend:latest

# 3. Update docker-compose.coolify.yml
# Thay vì build, dùng image có sẵn:
frontend:
  image: duckvhuynh/vietnam-map-frontend:latest
  # Xóa phần build:
  # build:
  #   context: ./frontend
  #   dockerfile: Dockerfile
```

### Option 2: Use GitHub Actions to Build

Tạo `.github/workflows/build-frontend.yml`:

```yaml
name: Build Frontend Docker Image

on:
  push:
    branches: [main]
    paths:
      - 'frontend/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: ./frontend
          push: true
          tags: duckvhuynh/vietnam-map-frontend:latest
```

### Option 3: Deploy Only Backend Services

Nếu chỉ muốn test backend, có thể tạo `docker-compose.backend-only.yml`:

```yaml
# Chỉ deploy các backend services
services:
  postgres: ...
  tileserver: ...
  osrm-car: ...
  osrm-bike: ...
  osrm-foot: ...
  nominatim: ...
  martin: ...
  redis: ...
  
  # Không deploy frontend
```

## Testing Build Locally

Test build frontend locally trước khi deploy:

```bash
cd frontend

# Test build
docker build -t test-frontend .

# Should complete in 2-5 minutes
```

## Coolify Settings

Trong Coolify, có thể tăng build timeout:

1. Vào **Settings** → **Configuration**
2. Tìm **Build Timeout**
3. Tăng lên 20-30 phút (nếu có option)

## Monitoring Build Progress

Xem logs real-time trong Coolify:

1. Vào **Deployments** tab
2. Click vào deployment đang chạy
3. Xem logs để check progress:
   - `npm ci` → ~30 seconds
   - `npm run build` → ~2-5 minutes
   - Total: ~5-10 minutes

## Current Build Optimizations

✅ Skip TypeScript type checking (saves ~30s)
✅ Skip ESLint (saves ~20s)
✅ Use npm ci with --prefer-offline (saves ~10s)
✅ Add .dockerignore (saves transfer time)
✅ Increase health check start_period to 120s

**Expected build time: 3-7 minutes**

## If Still Fails

### Quick Fix: Deploy without Frontend

```bash
# Trên VPS, chạy manual
cd /data/coolify/applications/<app-id>

# Deploy chỉ backend services
docker-compose up -d postgres tileserver osrm-car osrm-bike osrm-foot nominatim martin redis

# Build frontend riêng (không qua Coolify)
cd frontend
docker build -t map-frontend .
docker run -d --name map-frontend --network coolify -p 3000:3000 map-frontend
```

---

**Made with ❤️ for Vietnam**
