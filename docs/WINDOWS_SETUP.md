# Vietnam Map Server - Windows Setup Guide

## Cài đặt trên Windows

### Yêu cầu

- Windows 10/11 Pro hoặc Enterprise (cần Hyper-V)
- 16GB RAM (khuyến nghị)
- 50GB ổ cứng trống

### Option 1: Sử dụng WSL2 (Khuyến nghị)

#### 1. Cài đặt WSL2

Mở PowerShell as Administrator:

```powershell
# Enable WSL
wsl --install

# Hoặc nếu đã có WSL:
wsl --set-default-version 2
wsl --install -d Ubuntu-22.04

# Restart máy
```

#### 2. Setup Ubuntu trong WSL2

```bash
# Mở Ubuntu terminal
# Update system
sudo apt update && sudo apt upgrade -y

# Cài Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Logout và login lại
exit
# Mở lại Ubuntu terminal
```

#### 3. Clone project và setup

```bash
cd ~
mkdir projects
cd projects

# Clone project (hoặc copy files từ Windows)
# Nếu đã có folder trong Windows: /mnt/d/path/to/newmap
cd /mnt/d/Engineering\ Manager/gptchat/newmap

# Hoặc clone mới
git clone <repo-url> vietnam-map-server
cd vietnam-map-server

# Setup
cp .env.example .env
nano .env  # Sửa POSTGRES_PASSWORD
```

#### 4. Download và import dữ liệu

```bash
# Download OSM
bash scripts/download-vietnam-data.sh

# Start PostgreSQL
docker compose up -d postgres
sleep 10

# Import (mất 30-60 phút)
docker compose run --rm import-osm

# Routing
docker compose --profile import run --rm osrm-prepare-car

# Start all
docker compose up -d
```

#### 5. Truy cập

Mở browser trên Windows:
- Frontend: http://localhost
- API: http://localhost/route, /geocode

### Option 2: Docker Desktop (Dễ hơn nhưng chậm hơn)

#### 1. Cài Docker Desktop

- Download: https://www.docker.com/products/docker-desktop/
- Cài đặt và enable WSL2 backend
- Restart máy

#### 2. Clone project

```powershell
# Mở PowerShell
cd D:\
git clone <repo-url> vietnam-map-server
cd vietnam-map-server

# Hoặc extract ZIP nếu đã download
```

#### 3. Sửa line endings (quan trọng!)

```powershell
# Convert bash scripts từ CRLF sang LF
# Install Git Bash hoặc dùng editor
# Hoặc:
git config core.autocrlf input
git rm --cached -r .
git reset --hard
```

#### 4. Setup và chạy

```powershell
# Copy .env
copy .env.example .env
# Sửa file .env bằng Notepad/VSCode

# Download data - CHẠY TRONG GIT BASH
bash scripts/download-vietnam-data.sh

# HOẶC download manual:
# Vào https://download.geofabrik.de/asia/vietnam-latest.osm.pbf
# Lưu vào data\osm\vietnam-latest.osm.pbf

# Start services
docker-compose up -d postgres
# Đợi 10 giây
docker-compose run --rm import-osm
docker-compose --profile import run --rm osrm-prepare-car
docker-compose up -d
```

### Troubleshooting Windows

#### Lỗi: "This version of Windows does not support WSL2"

- Nâng cấp lên Windows 10 version 2004+ hoặc Windows 11
- Hoặc dùng Docker Toolbox (legacy)

#### Lỗi: Scripts không chạy được

```powershell
# Chuyển đổi line endings
# Dùng Git Bash:
bash -c "dos2unix scripts/*.sh"

# Hoặc dùng VSCode:
# Mở file .sh
# Bottom right: CRLF → LF
# Save
```

#### Lỗi: Docker container không start

```powershell
# Restart Docker Desktop
# Hoặc trong PowerShell Admin:
net stop com.docker.service
net start com.docker.service

# Tăng RAM cho Docker Desktop:
# Settings → Resources → Memory → 8GB
```

#### Lỗi: Out of memory

```powershell
# Tăng RAM cho WSL2
# Tạo file: C:\Users\<YourUsername>\.wslconfig

[wsl2]
memory=12GB
processors=4
swap=8GB
```

#### Lỗi: Permission denied

```bash
# Trong WSL2/Git Bash:
chmod +x scripts/*.sh
```

### Performance Tips

1. **Lưu project trong WSL filesystem** (nếu dùng WSL2)
   ```bash
   # Không nên: /mnt/c/Users/... (chậm)
   # Nên: ~/projects/... (nhanh)
   ```

2. **Tăng RAM cho Docker Desktop**
   - Settings → Resources → Memory: 8-12GB

3. **Disable Windows Defender scanning cho WSL**
   - Windows Security → Virus & threat protection
   - Exclusions → Add: `%USERPROFILE%\AppData\Local\Docker`

4. **Sử dụng SSD**

### Chạy scripts từ Windows

Nếu muốn chạy scripts từ PowerShell:

```powershell
# Install Git Bash
# Hoặc dùng wsl:

# Thay vì:
bash scripts/backup.sh

# Dùng:
wsl bash scripts/backup.sh

# Hoặc:
docker-compose run --rm postgres pg_dump -U mapuser mapdb > backup.sql
```

### Backup trên Windows

```powershell
# Backup
docker-compose exec postgres pg_dump -U mapuser mapdb | gzip > backup.sql.gz

# Restore
gunzip -c backup.sql.gz | docker-compose exec -T postgres psql -U mapuser mapdb
```

### Access từ mạng LAN

1. Mở firewall:
```powershell
# PowerShell Admin
New-NetFirewallRule -DisplayName "Vietnam Map Server" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
```

2. Truy cập từ máy khác:
```
http://<IP-máy-Windows>
```

## Visual Studio Code Integration

### Recommended Extensions

- Docker
- Remote - WSL
- Remote - Containers

### Workflow

1. Mở VSCode
2. Install "Remote - WSL" extension
3. Ctrl+Shift+P → "WSL: Connect to WSL"
4. Open project folder trong WSL

## Development trên Windows

```bash
# Frontend development
cd frontend
npm install
npm run dev
# → http://localhost:3000

# Edit code với VSCode
# Hot reload tự động
```

## Notes

- WSL2 nhanh hơn Docker Desktop rất nhiều
- Nên dùng WSL2 Ubuntu cho production-like environment
- Docker Desktop tiện hơn cho người mới
- RAM: càng nhiều càng tốt (minimum 8GB, recommend 16GB+)
