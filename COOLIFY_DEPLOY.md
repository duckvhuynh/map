# 🚀 Deploying Vietnam Map Server on Coolify

Complete guide to deploy your self-hosted map system using Coolify.

## 📋 Prerequisites

- Coolify installed on your VPS
- At least 8GB RAM and 50GB disk space
- Domain pointing to your server (map.duckvhuynh.space)
- GitHub repository: `duckvhuynh/map`

## 🎯 Deployment Methods

Choose one of these methods:

### Method 1: Deploy via Coolify UI (Recommended)

### Method 2: Deploy via Coolify CLI

---

## 📦 Method 1: Coolify UI Deployment

### Step 1: Create New Project

1. Log into Coolify dashboard
2. Go to **Projects** → **New Project**
3. Name: `Vietnam Map Server`
4. Click **Create**

### Step 2: Add Application

1. Click **New** → **Application**
2. Select **GitHub** as source
3. Choose repository: `duckvhuynh/map`
4. Branch: `main`
5. Click **Continue**

### Step 3: Configure Application Type

1. **Type**: Docker Compose
2. **Compose File**: Select `docker-compose.coolify.yml`
3. **Build Pack**: None (using docker-compose)
4. Click **Continue**

### Step 4: Configure Environment Variables

Add these environment variables in Coolify:

```bash
# Application
APP_NAME=vietnam-map-server
APP_DOMAIN=map.duckvhuynh.space
APP_URL=https://map.duckvhuynh.space

# Database (IMPORTANT: Generate secure password!)
POSTGRES_DB=mapdb
POSTGRES_USER=mapuser
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD_HERE

# PostgreSQL Performance
POSTGRES_SHARED_BUFFERS=2GB
POSTGRES_WORK_MEM=256MB
POSTGRES_MAINTENANCE_WORK_MEM=1GB

# Nominatim
NOMINATIM_THREADS=4

# Redis
REDIS_PORT=6379

# Frontend
NODE_ENV=production
```

**To generate secure password:**
```bash
openssl rand -base64 32
```

### Step 5: Configure Domain

1. Go to **Domains** tab
2. Add domain: `map.duckvhuynh.space`
3. Enable **HTTPS** (Coolify auto-generates Let's Encrypt cert)
4. Click **Save**

### Step 6: Configure Persistent Storage

Coolify should automatically detect volumes from `docker-compose.coolify.yml`:

- ✅ `postgres_data` - PostgreSQL database
- ✅ `nominatim_data` - Nominatim geocoding data
- ✅ `redis_data` - Redis cache
- ✅ `./data/osm` - OSM data files
- ✅ `./data/routing` - OSRM routing data

**Verify** these are mounted correctly in the **Storage** tab.

### Step 7: Pre-Deployment Setup

**IMPORTANT**: Before first deployment, you need to prepare data:

#### 7.1. Download Vietnam OSM Data

SSH into your VPS:

```bash
# Navigate to Coolify's project directory
cd /data/coolify/applications/<your-app-id>

# Create data directories
mkdir -p data/osm data/routing/{car,bike,foot}

# Download Vietnam OSM data (~301MB)
wget -O data/osm/vietnam-latest.osm.pbf \
  https://download.geofabrik.de/asia/vietnam-latest.osm.pbf

# Verify download
ls -lh data/osm/vietnam-latest.osm.pbf
```

#### 7.2. Download Required Configuration Files

```bash
# Create docker directories
mkdir -p docker/{postgres,tileserver/styles,osrm,imposm}

# PostgreSQL init script
cat > docker/postgres/init.sql << 'EOF'
-- Create required extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS unaccent;
EOF

# PostgreSQL config
cat > docker/postgres/postgresql.conf << 'EOF'
# Performance settings
shared_buffers = 2GB
work_mem = 256MB
maintenance_work_mem = 1GB
effective_cache_size = 6GB
max_wal_size = 2GB
checkpoint_completion_target = 0.9
random_page_cost = 1.1
EOF

# Download OSM Carto style
cd docker/imposm
wget https://raw.githubusercontent.com/gravitystorm/openstreetmap-carto/master/openstreetmap-carto.style
wget https://raw.githubusercontent.com/gravitystorm/openstreetmap-carto/master/openstreetmap-carto.lua
cd ../..

# Download OSRM profiles
cd docker/osrm
wget https://raw.githubusercontent.com/Project-OSRM/osrm-backend/master/profiles/car.lua
wget https://raw.githubusercontent.com/Project-OSRM/osrm-backend/master/profiles/bicycle.lua
wget https://raw.githubusercontent.com/Project-OSRM/osrm-backend/master/profiles/foot.lua

# Download OSRM lib directory
wget https://github.com/Project-OSRM/osrm-backend/archive/refs/heads/master.zip
unzip master.zip "osrm-backend-master/profiles/lib/*"
mv osrm-backend-master/profiles/lib .
rm -rf osrm-backend-master master.zip
cd ../..

# Create tileserver config
cat > docker/tileserver/config.json << 'EOF'
{
  "options": {
    "paths": {
      "root": "",
      "fonts": "/fonts",
      "sprites": "/sprites",
      "styles": "/styles",
      "mbtiles": "/data"
    }
  },
  "styles": {
    "osm-bright": {
      "style": "osm-bright/style.json",
      "tilejson": {
        "bounds": [102.14, 8.18, 109.46, 23.39]
      }
    }
  },
  "data": {}
}
EOF
```

### Step 8: Deploy Application

1. Click **Deploy** button
2. Watch deployment logs in real-time
3. Wait for all services to start (5-10 minutes)

**Expected deployment sequence:**
1. ✅ PostgreSQL starts (30s)
2. ✅ Redis starts (5s)
3. ✅ TileServer starts (10s)
4. ✅ Martin starts (waiting for PostgreSQL)
5. ✅ OSRM services start (waiting for routing data)
6. ✅ Nominatim starts (waiting for PostgreSQL)
7. ✅ Frontend builds and starts (2-3 minutes)

### Step 9: Import Data (First Time Only)

After deployment, you need to import OSM data:

#### 9.1. Import into PostgreSQL

SSH into VPS and run:

```bash
# Get container ID
docker ps | grep map-postgres

# Run import manually
docker exec -it map-postgres bash

# Inside container:
apt-get update && apt-get install -y osm2pgsql postgresql-client

# Import data
osm2pgsql -d mapdb -U mapuser --create --slim -G --hstore \
  --tag-transform-script /docker-entrypoint-initdb.d/openstreetmap-carto.lua \
  -C 2500 --number-processes 2 \
  --style /docker-entrypoint-initdb.d/openstreetmap-carto.style \
  /data/osm/vietnam-latest.osm.pbf

# Exit container
exit
```

**Expected time**: 30-60 minutes depending on CPU

#### 9.2. Prepare OSRM Routing Data

```bash
# Prepare car routing
docker run --rm -v $(pwd)/data/routing/car:/data \
  -v $(pwd)/data/osm:/osm:ro \
  -v $(pwd)/docker/osrm:/profiles:ro \
  osrm/osrm-backend:latest \
  bash -c "cp /osm/vietnam-latest.osm.pbf /data/ && cd /data && \
    osrm-extract -p /profiles/car.lua vietnam-latest.osm.pbf && \
    osrm-partition vietnam-latest.osrm && \
    osrm-customize vietnam-latest.osrm && \
    rm vietnam-latest.osm.pbf"

# Prepare bike routing
docker run --rm -v $(pwd)/data/routing/bike:/data \
  -v $(pwd)/data/osm:/osm:ro \
  -v $(pwd)/docker/osrm:/profiles:ro \
  osrm/osrm-backend:latest \
  bash -c "cp /osm/vietnam-latest.osm.pbf /data/ && cd /data && \
    osrm-extract -p /profiles/bicycle.lua vietnam-latest.osm.pbf && \
    osrm-partition vietnam-latest.osrm && \
    osrm-customize vietnam-latest.osrm && \
    rm vietnam-latest.osm.pbf"

# Prepare foot routing
docker run --rm -v $(pwd)/data/routing/foot:/data \
  -v $(pwd)/data/osm:/osm:ro \
  -v $(pwd)/docker/osrm:/profiles:ro \
  osrm/osrm-backend:latest \
  bash -c "cp /osm/vietnam-latest.osm.pbf /data/ && cd /data && \
    osrm-extract -p /profiles/foot.lua vietnam-latest.osm.pbf && \
    osrm-partition vietnam-latest.osrm && \
    osrm-customize vietnam-latest.osm.pbf && \
    rm vietnam-latest.osm.pbf"
```

**Expected time**: 10-20 minutes per profile

### Step 10: Restart Services

After data import:

1. Go to Coolify dashboard
2. Click **Restart All**
3. Wait for services to start

### Step 11: Verify Deployment

Check if everything is working:

```bash
# Health check
curl https://map.duckvhuynh.space/api/health

# Frontend
curl -I https://map.duckvhuynh.space

# Tiles (should return PNG image)
curl -I https://map.duckvhuynh.space/tiles/0/0/0.png

# Geocoding
curl "https://map.duckvhuynh.space/geocode?q=Hanoi&format=json"

# Routing
curl "https://map.duckvhuynh.space/route/v1/driving/105.8,21.0;106.7,20.8?overview=false"
```

---

## 📦 Method 2: Coolify CLI Deployment

### Install Coolify CLI

```bash
npm install -g @coollabsio/coolify-cli
```

### Login to Coolify

```bash
coolify login https://your-coolify-url.com
```

### Deploy Application

```bash
# Clone repository
git clone https://github.com/duckvhuynh/map.git
cd map

# Deploy with CLI
coolify deploy \
  --compose-file docker-compose.coolify.yml \
  --env-file .env.coolify \
  --domain map.duckvhuynh.space
```

---

## 🔍 Monitoring & Logs

### View Logs in Coolify

1. Go to **Logs** tab
2. Select service (frontend, postgres, nominatim, etc.)
3. View real-time logs

### Check Service Health

Coolify automatically monitors health checks defined in `docker-compose.coolify.yml`:

- ✅ Frontend: `/api/health`
- ✅ PostgreSQL: `pg_isready`
- ✅ Redis: `redis-cli ping`
- ✅ TileServer: `/health`
- ✅ OSRM: `/health`
- ✅ Nominatim: `/status`

### Resource Usage

Monitor in **Metrics** tab:
- CPU usage per service
- Memory consumption
- Network traffic
- Disk I/O

---

## 🔧 Troubleshooting

### Frontend Not Accessible

```bash
# Check frontend logs
docker logs map-frontend

# Check if frontend is running
docker ps | grep map-frontend

# Rebuild frontend
# In Coolify: Click "Rebuild" on frontend service
```

### Database Connection Errors

```bash
# Check PostgreSQL is running
docker ps | grep map-postgres

# Test connection
docker exec map-postgres pg_isready -U mapuser

# Check logs
docker logs map-postgres
```

### OSRM Routing Not Working

Routing data not prepared:

```bash
# Check if routing files exist
ls -lh data/routing/car/
ls -lh data/routing/bike/
ls -lh data/routing/foot/

# Should see vietnam-latest.osrm files
# If not, re-run OSRM preparation (Step 9.2)
```

### Nominatim Not Responding

```bash
# Check Nominatim startup (takes 5-10 minutes)
docker logs map-nominatim

# Check if data is imported
docker exec map-nominatim ls -lh /nominatim/data/
```

### Out of Memory

If services crash due to OOM:

1. Reduce `POSTGRES_SHARED_BUFFERS` to `1GB`
2. Reduce `NOMINATIM_THREADS` to `2`
3. Add swap space:

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 🎯 API Endpoints

Once deployed, access your map services:

- **Frontend**: https://map.duckvhuynh.space/
- **Health Check**: https://map.duckvhuynh.space/api/health
- **Map Tiles**: https://map.duckvhuynh.space/tiles/{z}/{x}/{y}.png
- **Geocoding**: https://map.duckvhuynh.space/geocode?q=Hanoi
- **Reverse Geocoding**: https://map.duckvhuynh.space/reverse?lat=21.028&lon=105.854
- **Routing (Car)**: https://map.duckvhuynh.space/route/v1/driving/105.8,21.0;106.7,20.8
- **Routing (Bike)**: https://map.duckvhuynh.space/route/bike/v1/cycling/105.8,21.0;106.7,20.8
- **Routing (Foot)**: https://map.duckvhuynh.space/route/foot/v1/walking/105.8,21.0;106.7,20.8
- **Vector Tiles**: https://map.duckvhuynh.space/vector/{table}/{z}/{x}/{y}.pbf

---

## 📊 Performance Optimization

### Enable Caching

Coolify can cache responses:

1. Go to **Settings** → **Cache**
2. Enable Redis cache
3. Set cache duration:
   - Tiles: 7 days
   - Geocoding: 1 hour
   - Routing: 1 hour

### Database Optimization

```sql
-- Connect to PostgreSQL
docker exec -it map-postgres psql -U mapuser -d mapdb

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_planet_osm_point_geom ON planet_osm_point USING GIST(way);
CREATE INDEX IF NOT EXISTS idx_planet_osm_line_geom ON planet_osm_line USING GIST(way);
CREATE INDEX IF NOT EXISTS idx_planet_osm_polygon_geom ON planet_osm_polygon USING GIST(way);

-- Vacuum and analyze
VACUUM ANALYZE;
```

### CDN Integration (Optional)

For production, consider adding CloudFlare CDN:

1. Point domain to CloudFlare
2. Enable **Proxy** mode
3. Enable caching rules for:
   - `/tiles/*` - Cache for 7 days
   - `*.png` - Cache for 7 days
   - `*.pbf` - Cache for 7 days

---

## 🔄 Updates & Maintenance

### Update OSM Data

```bash
# Download new data
wget -O data/osm/vietnam-latest.osm.pbf \
  https://download.geofabrik.de/asia/vietnam-latest.osm.pbf

# Re-import (in maintenance window)
docker exec -it map-postgres bash
# Run osm2pgsql import again

# Restart services
# In Coolify: Click "Restart All"
```

### Backup Database

```bash
# Backup PostgreSQL
docker exec map-postgres pg_dump -U mapuser mapdb > backup-$(date +%Y%m%d).sql

# Backup volumes (recommended)
cd /data/coolify/applications/<your-app-id>
tar czf backup-volumes-$(date +%Y%m%d).tar.gz postgres_data nominatim_data redis_data
```

### Update Application

Coolify auto-deploys on git push:

1. Push changes to GitHub
2. Coolify detects changes
3. Auto-rebuilds and deploys

Or manually:
1. Go to Coolify dashboard
2. Click **Redeploy**

---

## 🎉 Success!

Your Vietnam Map Server is now deployed on Coolify!

**Features:**
- ✅ Self-hosted map tiles
- ✅ Geocoding & reverse geocoding
- ✅ Car/bike/foot routing
- ✅ Automatic SSL via Traefik
- ✅ Health monitoring
- ✅ Auto-restart on failure
- ✅ Scalable architecture

**Next Steps:**
1. Customize map styles in `docker/tileserver/styles/`
2. Add custom POIs to PostgreSQL
3. Integrate into your applications
4. Monitor usage and optimize

---

## 📚 Additional Resources

- [Coolify Documentation](https://coolify.io/docs)
- [MapLibre GL JS Docs](https://maplibre.org/maplibre-gl-js-docs/)
- [OSRM API Documentation](http://project-osrm.org/docs/v5.24.0/api/)
- [Nominatim API Docs](https://nominatim.org/release-docs/latest/api/Overview/)
- [OpenStreetMap Wiki](https://wiki.openstreetmap.org/)

---

**Need Help?**
- Check Coolify logs
- Review service health checks
- Verify environment variables
- Check disk space and memory
- Ensure all data is imported

**Common Issues:**
- Data import not completed → Re-run import steps
- Out of memory → Reduce buffer sizes, add swap
- Services not starting → Check depends_on and health checks
- Domain not resolving → Verify DNS and Traefik configuration
