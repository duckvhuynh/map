# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-01

### Added
- Initial release of Vietnam Map Server
- OpenStreetMap tile server for Vietnam
- OSRM routing engine (car, bike, foot profiles)
- Nominatim geocoding service
- Distance matrix API
- Route optimization (TSP)
- Isochrone API
- Vector tiles support via Martin
- Web frontend demo application
- Docker Compose orchestration
- Nginx reverse proxy with rate limiting
- PostgreSQL + PostGIS database
- Automated OSM data import scripts
- Backup and restore scripts
- SSL/HTTPS setup script
- Comprehensive documentation
  - Installation guide
  - API documentation
  - Deployment guide
  - Quick start guide
- Example API usage in multiple languages

### Features
- ✅ Map tile serving (raster and vector)
- ✅ Turn-by-turn navigation
- ✅ Forward and reverse geocoding
- ✅ Distance and duration calculations
- ✅ Multi-point route optimization
- ✅ Isochrone generation
- ✅ Nearest road snapping
- ✅ Map matching for GPS traces

### Supported Regions
- Vietnam (full coverage)
- Expandable to other regions via Geofabrik downloads

### Technical Stack
- Docker & Docker Compose
- PostgreSQL 15 + PostGIS 3.3
- OSRM (Open Source Routing Machine)
- Nominatim 4.4
- TileServer GL
- Martin (vector tiles)
- Next.js 14 (frontend)
- Nginx (reverse proxy)
- MapLibre GL JS

### Documentation
- README.md - Overview and quick start
- QUICKSTART.md - Fast setup guide
- docs/INSTALLATION.md - Detailed installation
- docs/API.md - Complete API reference
- docs/DEPLOYMENT.md - Production deployment guide
- CONTRIBUTING.md - Contribution guidelines

### Scripts
- download-vietnam-data.sh - Download OSM data
- setup.sh - Initial setup wizard
- backup.sh - Database backup
- update-osm-data.sh - Update OSM data
- setup-ssl.sh - SSL certificate setup

### Configuration
- Environment-based configuration (.env)
- PostgreSQL performance tuning
- Nginx caching and rate limiting
- Docker resource limits
- Customizable ports

## [Unreleased]

### Planned Features
- [ ] Motorcycle routing profile
- [ ] Bus/public transport routing
- [ ] Real-time traffic data integration
- [ ] 3D building rendering
- [ ] POI search and categorization
- [ ] Offline map support
- [ ] Mobile SDK (iOS/Android)
- [ ] Prometheus metrics export
- [ ] Grafana dashboards
- [ ] Automated tests
- [ ] CI/CD pipelines
- [ ] Multiple language support
- [ ] Admin dashboard

### Known Issues
- Nominatim import can be slow on systems with less than 16GB RAM
- First-time routing requests may be slower due to cache warming
- Large route calculations (>1000km) may timeout

### Notes
- OSM data for Vietnam is approximately 1.5GB
- Full import takes 30-60 minutes on recommended hardware
- Routing data preparation takes 15-30 minutes
- Requires at least 8GB RAM for smooth operation
- Recommended 16GB+ RAM for production

---

For more details, see the [README](README.md) and [documentation](docs/).
