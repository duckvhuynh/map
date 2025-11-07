#!/bin/bash

# Setup Script for Vietnam Map Server
# This script sets up the entire map server infrastructure

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "================================================"
echo "Vietnam Map Server - Initial Setup"
echo "================================================"
echo ""

cd "$PROJECT_DIR"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not installed."
    echo "Please install Docker Compose plugin."
    exit 1
fi

echo "✓ Docker and Docker Compose are installed"
echo ""

# Create .env file if not exists
if [ ! -f .env ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
    echo "✓ Created .env file"
    echo "⚠ Please update .env with your settings, especially POSTGRES_PASSWORD"
    echo ""
fi

# Create necessary directories
echo "Creating data directories..."
mkdir -p data/osm data/tiles data/routing/{car,bike,foot}
mkdir -p docker/nginx/ssl
echo "✓ Directories created"
echo ""

# Download OSM data
echo "================================================"
echo "Step 1: Download Vietnam OSM Data"
echo "================================================"
read -p "Do you want to download Vietnam OSM data now? (~1.5GB) (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    bash scripts/download-vietnam-data.sh
else
    echo "Skipped. You can download later with: bash scripts/download-vietnam-data.sh"
fi
echo ""

# Start PostgreSQL
echo "================================================"
echo "Step 2: Start PostgreSQL"
echo "================================================"
read -p "Start PostgreSQL now? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Starting PostgreSQL..."
    docker compose up -d postgres
    echo "Waiting for PostgreSQL to be ready..."
    sleep 10
    echo "✓ PostgreSQL started"
else
    echo "Skipped. You can start later with: docker-compose up -d postgres"
fi
echo ""

# Import OSM data
if [ -f "data/osm/vietnam-latest.osm.pbf" ]; then
    echo "================================================"
    echo "Step 3: Import OSM Data"
    echo "================================================"
    read -p "Import OSM data to PostgreSQL? (this may take 30-60 min) (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "Importing OSM data..."
        docker compose run --rm import-osm
        echo "✓ OSM data imported"
    else
        echo "Skipped. You can import later with: docker-compose run --rm import-osm"
    fi
    echo ""
fi

# Prepare routing data
if [ -f "data/osm/vietnam-latest.osm.pbf" ]; then
    echo "================================================"
    echo "Step 4: Prepare Routing Data"
    echo "================================================"
    read -p "Prepare routing data for OSRM? (this may take 15-30 min) (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "Preparing routing data for car..."
        docker compose --profile import run --rm osrm-prepare-car
        echo "✓ Car routing data prepared"
    else
        echo "Skipped. You can prepare later with: docker-compose --profile import run --rm osrm-prepare-car"
    fi
    echo ""
fi

# Start all services
echo "================================================"
echo "Step 5: Start All Services"
echo "================================================"
read -p "Start all map services now? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Starting all services..."
    docker compose up -d
    echo "✓ All services started"
else
    echo "Skipped. You can start later with: docker-compose up -d"
fi
echo ""

echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Services should be available at:"
echo "  - Frontend: http://localhost"
echo "  - Tile Server: http://localhost:8080"
echo "  - Routing API: http://localhost:5000"
echo "  - Geocoding: http://localhost:7070"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop all: docker-compose down"
echo "  - Restart: docker-compose restart"
echo ""
echo "For more information, see README.md"
echo "================================================"
