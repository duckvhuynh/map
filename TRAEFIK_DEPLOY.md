# Deploying with Traefik (Coolify)

## What Changed

We've switched from Nginx to **Traefik** as the reverse proxy since you already have Coolify/Traefik running on your VPS.

### Architecture:
```
Internet → Traefik (ports 80/443) → Frontend Container (port 3000)
                                      ↓
                    Frontend proxies to: Tiles, Routing, Geocoding
```

## Deployment Steps

### 1. On VPS, pull the latest code:
```bash
cd ~/map
git pull origin main
```

### 2. Stop any old containers:
```bash
docker-compose down --remove-orphans
```

### 3. Verify Traefik network exists:
```bash
docker network ls | grep coolify
```
Expected output: `coolify` network should exist.

If it doesn't exist, check for other Traefik networks:
```bash
docker network ls | grep -i traefik
```

**If the network has a different name**, update `docker-compose.yml`:
```yaml
networks:
  coolify:  # Change this to your actual network name
    external: true
```

### 4. Run the deployment script:
```bash
bash deploy.sh
```

The script will:
- ✅ Verify Traefik network exists
- ✅ Download Vietnam OSM data (if not already)
- ✅ Import data to PostgreSQL (if not already)
- ✅ Prepare OSRM routing data
- ✅ Build and start all containers
- ✅ Frontend will automatically be detected by Traefik

### 5. Verify Traefik routing:

Check Traefik detected the frontend:
```bash
docker logs coolify-proxy | grep map-frontend
```

Test the website:
```bash
curl -I https://map.duckvhuynh.space
```

### 6. Access your map:
🌐 **https://map.duckvhuynh.space**

## How It Works

### Traefik Labels
The `frontend` service has these labels that Traefik automatically detects:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.map-frontend.rule=Host(`map.duckvhuynh.space`)"
  - "traefik.http.routers.map-frontend.entrypoints=websecure"
  - "traefik.http.routers.map-frontend.tls=true"
  - "traefik.http.services.map-frontend.loadbalancer.server.port=3000"
```

### Next.js Rewrites
The frontend proxies API requests:
- `/tiles/*` → TileServer (port 8080)
- `/geocode` → Nominatim (port 8080)
- `/route/*` → OSRM services (ports 5000/5001/5002)
- `/vector/*` → Martin (port 3000)

## Troubleshooting

### Frontend not accessible
```bash
# Check if frontend is running
docker ps | grep map-frontend

# Check frontend logs
docker logs map-frontend

# Check Traefik logs
docker logs coolify-proxy | tail -50
```

### SSL not working
Traefik should use your existing Let's Encrypt certificates. Check:
```bash
docker exec coolify-proxy cat /etc/traefik/traefik.yml
```

### Backend services not responding
```bash
# Check all services
docker-compose ps

# Check specific service logs
docker logs map-tileserver
docker logs map-nominatim
docker logs map-osrm-car
```

### OSRM routing not working
Re-run OSRM preparation (now includes lib/ directory):
```bash
docker-compose --profile import run --rm osrm-prepare-car
docker-compose --profile import run --rm osrm-prepare-bike
docker-compose --profile import run --rm osrm-prepare-foot
```

## API Endpoints

Once deployed, all services are available via the domain:

- **Frontend**: https://map.duckvhuynh.space/
- **Tiles**: https://map.duckvhuynh.space/tiles/{z}/{x}/{y}.png
- **Geocoding**: https://map.duckvhuynh.space/geocode?q=Hanoi
- **Reverse Geocoding**: https://map.duckvhuynh.space/reverse?lat=21.028&lon=105.854
- **Routing (Car)**: https://map.duckvhuynh.space/route/v1/driving/105.8,21.0;106.7,20.8
- **Routing (Bike)**: https://map.duckvhuynh.space/route/bike/v1/cycling/105.8,21.0;106.7,20.8
- **Routing (Foot)**: https://map.duckvhuynh.space/route/foot/v1/walking/105.8,21.0;106.7,20.8
- **Vector Tiles**: https://map.duckvhuynh.space/vector/{table}/{z}/{x}/{y}.pbf

## Benefits of Traefik

✅ **Automatic SSL** - Traefik manages certificates  
✅ **Service Discovery** - Automatically detects new containers  
✅ **Load Balancing** - Built-in load balancer  
✅ **No manual Nginx config** - Everything via Docker labels  
✅ **Unified reverse proxy** - Same proxy for all Coolify apps  

## Notes

- Traefik already handles ports 80 and 443
- All backend services bind to `127.0.0.1` only (not exposed externally)
- Only the frontend is exposed via Traefik
- Frontend acts as reverse proxy to internal services
- No need to manage Nginx configs or SSL certificates manually
