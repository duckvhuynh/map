#!/bin/bash

# Update OSM Data Script
# Downloads latest Vietnam OSM data and updates the database

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data/osm"
LOG_FILE="$PROJECT_DIR/logs/update_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$PROJECT_DIR/logs"

exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "================================================"
echo "Vietnam Map Server - OSM Data Update"
echo "Started: $(date)"
echo "================================================"
echo ""

cd "$PROJECT_DIR"

# Source environment
if [ -f .env ]; then
    source .env
fi

OSM_URL=${OSM_DOWNLOAD_URL:-https://download.geofabrik.de/asia/vietnam-latest.osm.pbf}

# Backup current database
echo "Creating database backup before update..."
bash scripts/backup.sh

# Download new OSM data
echo ""
echo "Downloading latest OSM data..."
mv "$DATA_DIR/vietnam-latest.osm.pbf" "$DATA_DIR/vietnam-latest.osm.pbf.old" || true

if command -v wget &> /dev/null; then
    wget -c -O "$DATA_DIR/vietnam-latest.osm.pbf" "$OSM_URL"
elif command -v curl &> /dev/null; then
    curl -L -o "$DATA_DIR/vietnam-latest.osm.pbf" "$OSM_URL"
fi

# Verify download
if [ ! -f "$DATA_DIR/vietnam-latest.osm.pbf" ]; then
    echo "✗ Download failed! Restoring old file..."
    mv "$DATA_DIR/vietnam-latest.osm.pbf.old" "$DATA_DIR/vietnam-latest.osm.pbf"
    exit 1
fi

echo "✓ Download completed"

# Stop services
echo ""
echo "Stopping services..."
docker compose stop osrm-car nominatim

# Re-import OSM data
echo ""
echo "Importing new OSM data..."
docker compose run --rm import-osm

# Re-prepare routing data
echo ""
echo "Preparing new routing data..."
docker compose --profile import run --rm osrm-prepare-car

# Restart services
echo ""
echo "Restarting services..."
docker compose up -d

# Clean up old data
rm -f "$DATA_DIR/vietnam-latest.osm.pbf.old"

echo ""
echo "================================================"
echo "Update completed: $(date)"
echo "Log file: $LOG_FILE"
echo "================================================"
