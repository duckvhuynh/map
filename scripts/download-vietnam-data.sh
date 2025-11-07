#!/bin/bash

# Download Vietnam OSM Data
# Script to download OpenStreetMap data for Vietnam

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data/osm"

echo "================================================"
echo "Vietnam Map Server - OSM Data Download"
echo "================================================"
echo ""

# Create data directory if not exists
mkdir -p "$DATA_DIR"

# Source environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

# Default values
OSM_REGION=${OSM_REGION:-vietnam}
OSM_URL=${OSM_DOWNLOAD_URL:-https://download.geofabrik.de/asia/vietnam-latest.osm.pbf}
OSM_FILE="$DATA_DIR/vietnam-latest.osm.pbf"

echo "Download URL: $OSM_URL"
echo "Destination: $OSM_FILE"
echo ""

# Check if file already exists
if [ -f "$OSM_FILE" ]; then
    echo "OSM file already exists: $OSM_FILE"
    read -p "Do you want to re-download? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping download."
        exit 0
    fi
    rm -f "$OSM_FILE"
fi

# Download OSM data
echo "Downloading Vietnam OSM data..."
echo "This may take 10-30 minutes depending on your connection..."
echo ""

if command -v wget &> /dev/null; then
    wget -c -O "$OSM_FILE" "$OSM_URL"
elif command -v curl &> /dev/null; then
    curl -L -o "$OSM_FILE" "$OSM_URL"
else
    echo "Error: Neither wget nor curl is installed."
    echo "Please install wget or curl and try again."
    exit 1
fi

# Verify download
if [ -f "$OSM_FILE" ]; then
    FILE_SIZE=$(du -h "$OSM_FILE" | cut -f1)
    echo ""
    echo "✓ Download completed successfully!"
    echo "File size: $FILE_SIZE"
    echo "Location: $OSM_FILE"
    echo ""
    echo "You can now run: docker-compose --profile import up"
else
    echo ""
    echo "✗ Download failed!"
    exit 1
fi

echo ""
echo "================================================"
echo "Next steps:"
echo "1. Start PostgreSQL: docker-compose up -d postgres"
echo "2. Import OSM data: docker-compose run --rm import-osm"
echo "3. Prepare routing: docker-compose --profile import run --rm osrm-prepare-car"
echo "4. Start all services: docker-compose up -d"
echo "================================================"
