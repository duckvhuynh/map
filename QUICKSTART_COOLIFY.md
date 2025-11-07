# 🎯 Quick Start - Deploy to Coolify in 3 Steps

## Step 1: Create New Application in Coolify

1. Open Coolify dashboard
2. **Projects** → **New Project** → Name: `Vietnam Map Server`
3. **New** → **Application** → **GitHub** → Repository: `duckvhuynh/map`
4. **Type**: Docker Compose
5. **Compose File**: `docker-compose.coolify.yml`

## Step 2: Set Environment Variables

In Coolify's Environment Variables section, add:

```env
APP_DOMAIN=map.duckvhuynh.space
APP_URL=https://map.duckvhuynh.space
POSTGRES_PASSWORD=<generate-strong-password>
POSTGRES_DB=mapdb
POSTGRES_USER=mapuser
```

Generate password:
```bash
openssl rand -base64 32
```

## Step 3: Deploy & Import Data

### 3.1. Deploy Application
- Click **Deploy** in Coolify
- Wait 5-10 minutes for services to start

### 3.2. Prepare Data (One-time)
SSH into your VPS:

```bash
# Find your app directory
cd /data/coolify/applications/<your-app-id>

# Run setup script
bash setup-coolify.sh

# Wait for prompt, enter app directory path
# Script downloads Vietnam OSM data (~301MB) and configs
```

### 3.3. Import Data
```bash
# After deploy completes
bash import-data.sh

# This imports OSM data (30-60 min)
# Prepares routing (30-60 min)
```

### 3.4. Restart Services
- Go to Coolify dashboard
- Click **Restart All**

## ✅ Done!

Your map is live at: **https://map.duckvhuynh.space**

### Test It:
- Frontend: https://map.duckvhuynh.space/
- Health: https://map.duckvhuynh.space/api/health
- Tiles: https://map.duckvhuynh.space/tiles/0/0/0.png
- Geocoding: https://map.duckvhuynh.space/geocode?q=Hanoi

---

## 📚 Full Documentation

- **Complete Guide**: [COOLIFY_DEPLOY.md](./COOLIFY_DEPLOY.md)
- **Troubleshooting**: See COOLIFY_DEPLOY.md Section "Troubleshooting"
- **API Docs**: [API.md](./API.md)

---

## ⚙️ Architecture

```
Internet
   ↓
Traefik (Coolify - ports 80/443)
   ↓
Frontend Container (Next.js - port 3000)
   ├─→ /tiles → TileServer (8080)
   ├─→ /geocode → Nominatim (8080)
   ├─→ /route → OSRM (5000/5001/5002)
   └─→ /vector → Martin (3000)
   
All services connect to:
   PostgreSQL + PostGIS (5432)
```

---

## 🔥 Features

✅ Self-hosted map tiles (Vietnam)
✅ Geocoding & reverse geocoding
✅ Car/Bike/Foot routing
✅ Automatic SSL (Let's Encrypt)
✅ Health monitoring
✅ Auto-restart on failure
✅ Scalable architecture

---

## 💡 Pro Tips

1. **First deployment takes time**: OSM import ~30-60 min, OSRM prepare ~30-60 min
2. **Monitor logs**: Use Coolify's Logs tab to watch progress
3. **Check health**: Use `/api/health` endpoint
4. **Optimize**: After import, database indexes are auto-created
5. **Update data**: Re-download vietnam-latest.osm.pbf monthly

---

## 🆘 Need Help?

**Common Issues:**
- Services not starting → Check logs in Coolify
- Import failed → Ensure enough disk space (50GB+)
- Out of memory → Reduce POSTGRES_SHARED_BUFFERS to 1GB
- Routing not working → Run import-data.sh to prepare OSRM data

**Quick Checks:**
```bash
# Check all containers
docker ps | grep map-

# Check PostgreSQL
docker exec map-postgres pg_isready -U mapuser

# Check logs
docker logs map-frontend
docker logs map-postgres
```

---

**Made with ❤️ for Vietnam**
