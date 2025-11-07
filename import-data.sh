#!/bin/bash

#########################################
# Vietnam Map Server - Data Import Script
# Run this AFTER deploying to Coolify
# This imports OSM data and prepares routing
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

print_status "========================================="
print_status "Vietnam Map Server - Data Import"
print_status "========================================="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

#########################################
# 1. Check PostgreSQL is running
#########################################
print_status "Step 1: Checking PostgreSQL..."

if ! docker ps | grep -q map-postgres; then
    print_error "PostgreSQL container 'map-postgres' is not running"
    print_status "Please start the application in Coolify first"
    exit 1
fi

print_success "PostgreSQL is running"
echo ""

#########################################
# 2. Wait for PostgreSQL to be ready
#########################################
print_status "Step 2: Waiting for PostgreSQL to be ready..."

for i in {1..30}; do
    if docker exec map-postgres pg_isready -U mapuser -d mapdb &> /dev/null; then
        print_success "PostgreSQL is ready"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

#########################################
# 3. Check if data already imported
#########################################
print_status "Step 3: Checking existing data..."

TABLE_COUNT=$(docker exec map-postgres psql -U mapuser -d mapdb -tAc \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE 'planet_osm_%'" 2>/dev/null || echo "0")

if [ "$TABLE_COUNT" -gt 3 ]; then
    print_warning "Data already imported ($TABLE_COUNT OSM tables found)"
    read -p "Re-import data? This will take 30-60 minutes (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping import"
        SKIP_IMPORT=true
    fi
fi
echo ""

#########################################
# 4. Import OSM data to PostgreSQL
#########################################
if [ "$SKIP_IMPORT" != "true" ]; then
    print_status "Step 4: Importing OSM data to PostgreSQL..."
    print_warning "This will take 30-60 minutes. Please be patient."
    echo ""

    # Install osm2pgsql in PostgreSQL container
    docker exec map-postgres bash -c "
        apt-get update -qq && apt-get install -y -qq osm2pgsql wget curl
    "

    # Run import
    docker exec map-postgres bash -c "
        osm2pgsql -d mapdb -U mapuser \
            --create --slim -G --hstore \
            --tag-transform-script /data/osm/openstreetmap-carto.lua \
            -C 2500 --number-processes 2 \
            --style /data/osm/openstreetmap-carto.style \
            /data/osm/vietnam-latest.osm.pbf
    "

    print_success "OSM import complete!"
else
    print_status "Step 4: Skipping OSM import"
fi
echo ""

#########################################
# 5. Prepare OSRM routing data
#########################################
print_status "Step 5: Preparing OSRM routing data..."

prepare_routing() {
    local profile=$1
    local file="data/routing/$profile/vietnam-latest.osrm"
    
    if [ -f "$file" ]; then
        print_warning "Routing data for $profile already exists"
        read -p "Re-prepare? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    print_status "Preparing routing for $profile (10-20 minutes)..."
    
    docker run --rm \
        -v "$(pwd)/data/routing/$profile:/data" \
        -v "$(pwd)/data/osm:/osm:ro" \
        -v "$(pwd)/docker/osrm:/profiles:ro" \
        osrm/osrm-backend:latest \
        bash -c "
            cp /osm/vietnam-latest.osm.pbf /data/ && \
            cd /data && \
            osrm-extract -p /profiles/${profile}.lua vietnam-latest.osm.pbf && \
            osrm-partition vietnam-latest.osrm && \
            osrm-customize vietnam-latest.osrm && \
            rm vietnam-latest.osm.pbf
        "
    
    print_success "Routing for $profile complete"
}

# Get current directory
CURRENT_DIR=$(pwd)

# Prepare routing for each profile
cd "$CURRENT_DIR"
prepare_routing "car"
cd "$CURRENT_DIR"
prepare_routing "bicycle"
cd "$CURRENT_DIR"
prepare_routing "foot"

echo ""

#########################################
# 6. Create indexes for better performance
#########################################
print_status "Step 6: Creating database indexes..."

docker exec map-postgres psql -U mapuser -d mapdb << 'EOF'
-- Create spatial indexes
CREATE INDEX IF NOT EXISTS idx_planet_osm_point_geom ON planet_osm_point USING GIST(way);
CREATE INDEX IF NOT EXISTS idx_planet_osm_line_geom ON planet_osm_line USING GIST(way);
CREATE INDEX IF NOT EXISTS idx_planet_osm_polygon_geom ON planet_osm_polygon USING GIST(way);
CREATE INDEX IF NOT EXISTS idx_planet_osm_roads_geom ON planet_osm_roads USING GIST(way);

-- Create attribute indexes
CREATE INDEX IF NOT EXISTS idx_planet_osm_point_tags ON planet_osm_point USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_planet_osm_line_tags ON planet_osm_line USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_planet_osm_polygon_tags ON planet_osm_polygon USING GIN(tags);

-- Vacuum and analyze
VACUUM ANALYZE;
EOF

print_success "Indexes created"
echo ""

#########################################
# Summary
#########################################
print_status "========================================="
print_success "Data Import Complete!"
print_status "========================================="
echo ""
print_status "✅ PostgreSQL verified"
print_status "✅ OSM data imported"
print_status "✅ OSRM routing data prepared (car, bike, foot)"
print_status "✅ Database indexes created"
echo ""
print_status "Next Steps:"
echo "1. Go to Coolify dashboard"
echo "2. Click 'Restart All' to restart all services"
echo "3. Wait 2-3 minutes for services to start"
echo "4. Test your map at: https://map.duckvhuynh.space"
echo ""
print_success "Your Vietnam Map Server is ready!"
print_status "========================================="
