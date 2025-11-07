#!/bin/bash

#########################################
# Vietnam Map Server - Coolify Pre-Setup
# Run this BEFORE deploying to Coolify
# This prepares all required data and configs
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

print_status "========================================="
print_status "Vietnam Map Server - Coolify Pre-Setup"
print_status "========================================="
echo ""

# Get Coolify app directory
read -p "Enter your Coolify app directory path (e.g., /data/coolify/applications/xxx): " APP_DIR

if [ ! -d "$APP_DIR" ]; then
    print_error "Directory does not exist: $APP_DIR"
    exit 1
fi

cd "$APP_DIR"
print_success "Working in: $(pwd)"
echo ""

#########################################
# 1. Create directories
#########################################
print_status "Step 1: Creating directories..."
mkdir -p data/osm data/routing/{car,bike,foot} data/tiles
mkdir -p docker/{postgres,tileserver/styles,osrm,imposm}
print_success "Directories created"
echo ""

#########################################
# 2. Download Vietnam OSM data
#########################################
print_status "Step 2: Downloading Vietnam OSM data..."

if [ -f "data/osm/vietnam-latest.osm.pbf" ]; then
    print_success "OSM data already exists ($(du -h data/osm/vietnam-latest.osm.pbf | cut -f1))"
else
    print_status "Downloading from Geofabrik (~301MB)..."
    wget -c -O data/osm/vietnam-latest.osm.pbf \
        https://download.geofabrik.de/asia/vietnam-latest.osm.pbf
    print_success "Download complete: $(du -h data/osm/vietnam-latest.osm.pbf | cut -f1)"
fi
echo ""

#########################################
# 3. Create PostgreSQL configs
#########################################
print_status "Step 3: Creating PostgreSQL configurations..."

cat > docker/postgres/init.sql << 'EOF'
-- Vietnam Map Server - PostgreSQL Initialization
-- Create required extensions for PostGIS and OSM

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Performance settings
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET work_mem = '256MB';
ALTER SYSTEM SET maintenance_work_mem = '1GB';
ALTER SYSTEM SET effective_cache_size = '6GB';
EOF

cat > docker/postgres/postgresql.conf << 'EOF'
# Vietnam Map Server - PostgreSQL Configuration
# Optimized for OSM data and PostGIS

# Memory Settings
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 256MB
maintenance_work_mem = 1GB

# WAL Settings
wal_buffers = 16MB
max_wal_size = 2GB
min_wal_size = 1GB
checkpoint_completion_target = 0.9

# Query Planner
random_page_cost = 1.1
effective_io_concurrency = 200

# Performance
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
EOF

print_success "PostgreSQL configs created"
echo ""

#########################################
# 4. Download OSM Carto style
#########################################
print_status "Step 4: Downloading OpenStreetMap Carto style..."

cd docker/imposm
if [ ! -f "openstreetmap-carto.style" ]; then
    wget -q https://raw.githubusercontent.com/gravitystorm/openstreetmap-carto/master/openstreetmap-carto.style
    print_success "Downloaded openstreetmap-carto.style"
else
    print_success "openstreetmap-carto.style already exists"
fi

if [ ! -f "openstreetmap-carto.lua" ]; then
    wget -q https://raw.githubusercontent.com/gravitystorm/openstreetmap-carto/master/openstreetmap-carto.lua
    print_success "Downloaded openstreetmap-carto.lua"
else
    print_success "openstreetmap-carto.lua already exists"
fi
cd ../..
echo ""

#########################################
# 5. Download OSRM profiles
#########################################
print_status "Step 5: Downloading OSRM routing profiles..."

cd docker/osrm

# Download profile files
for profile in car bicycle foot; do
    if [ ! -f "${profile}.lua" ]; then
        wget -q https://raw.githubusercontent.com/Project-OSRM/osrm-backend/master/profiles/${profile}.lua
        print_success "Downloaded ${profile}.lua"
    else
        print_success "${profile}.lua already exists"
    fi
done

# Download lib directory
if [ ! -d "lib" ]; then
    print_status "Downloading OSRM lib directory..."
    wget -q https://github.com/Project-OSRM/osrm-backend/archive/refs/heads/master.zip
    unzip -q master.zip "osrm-backend-master/profiles/lib/*"
    mv osrm-backend-master/profiles/lib .
    rm -rf osrm-backend-master master.zip
    print_success "OSRM lib directory downloaded"
else
    print_success "OSRM lib directory already exists"
fi
cd ../..
echo ""

#########################################
# 6. Create TileServer config
#########################################
print_status "Step 6: Creating TileServer configuration..."

cat > docker/tileserver/config.json << 'EOF'
{
  "options": {
    "paths": {
      "root": "",
      "fonts": "/fonts",
      "sprites": "/sprites",
      "styles": "/styles",
      "mbtiles": "/data"
    },
    "serveAllFonts": true
  },
  "styles": {
    "osm-bright": {
      "style": "osm-bright/style.json",
      "tilejson": {
        "type": "overlay",
        "bounds": [102.14, 8.18, 109.46, 23.39]
      }
    }
  },
  "data": {}
}
EOF

print_success "TileServer config created"
echo ""

#########################################
# 7. Set permissions
#########################################
print_status "Step 7: Setting permissions..."
chmod -R 755 data docker
print_success "Permissions set"
echo ""

#########################################
# Summary
#########################################
print_status "========================================="
print_success "Pre-Setup Complete!"
print_status "========================================="
echo ""
print_status "✅ Created directory structure"
print_status "✅ Downloaded Vietnam OSM data ($(du -h data/osm/vietnam-latest.osm.pbf | cut -f1))"
print_status "✅ Created PostgreSQL configurations"
print_status "✅ Downloaded OpenStreetMap Carto style"
print_status "✅ Downloaded OSRM routing profiles + lib"
print_status "✅ Created TileServer configuration"
echo ""
print_status "Next Steps:"
echo "1. Deploy application in Coolify using docker-compose.coolify.yml"
echo "2. Wait for PostgreSQL to start"
echo "3. Run data import script: bash import-data.sh"
echo "4. Restart all services in Coolify"
echo ""
print_success "Ready for Coolify deployment!"
print_status "========================================="
