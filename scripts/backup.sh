#!/bin/bash

# Backup Script for Vietnam Map Server
# Backs up PostgreSQL database and configuration

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "================================================"
echo "Vietnam Map Server - Backup"
echo "================================================"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Source environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

POSTGRES_USER=${POSTGRES_USER:-mapuser}
POSTGRES_DB=${POSTGRES_DB:-mapdb}

echo "Backing up database: $POSTGRES_DB"
echo "Backup location: $BACKUP_DIR"
echo ""

# Backup PostgreSQL database
BACKUP_FILE="$BACKUP_DIR/mapdb_backup_$TIMESTAMP.sql"
echo "Creating database backup..."

docker compose exec -T postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > "$BACKUP_FILE"

if [ -f "$BACKUP_FILE" ]; then
    # Compress backup
    echo "Compressing backup..."
    gzip "$BACKUP_FILE"
    BACKUP_FILE="$BACKUP_FILE.gz"
    
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo ""
    echo "✓ Backup completed successfully!"
    echo "File: $BACKUP_FILE"
    echo "Size: $FILE_SIZE"
else
    echo "✗ Backup failed!"
    exit 1
fi

# Backup configuration files
CONFIG_BACKUP="$BACKUP_DIR/config_backup_$TIMESTAMP.tar.gz"
echo ""
echo "Backing up configuration files..."

cd "$PROJECT_DIR"
tar -czf "$CONFIG_BACKUP" \
    .env \
    docker-compose.yml \
    docker/nginx/conf.d/ \
    docker/postgres/postgresql.conf \
    docker/imposm/mapping.yml \
    docker/tileserver/config.json

echo "✓ Configuration backup created: $CONFIG_BACKUP"

# Clean old backups (keep last 7 days)
echo ""
echo "Cleaning old backups (keeping last 7 days)..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "config_backup_*.tar.gz" -mtime +7 -delete
echo "✓ Old backups cleaned"

echo ""
echo "================================================"
echo "Backup Summary"
echo "================================================"
echo "Database backup: $BACKUP_FILE"
echo "Config backup: $CONFIG_BACKUP"
echo ""
echo "To restore database:"
echo "  gunzip -c $BACKUP_FILE | docker-compose exec -T postgres psql -U $POSTGRES_USER $POSTGRES_DB"
echo "================================================"
