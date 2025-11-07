# API Documentation - Vietnam Map Server

## Base URL

```
http://localhost
```

Hoặc production:
```
https://yourdomain.com
```

## Authentication

Hiện tại API không yêu cầu authentication. Để production, bạn nên thêm rate limiting và API keys.

## Endpoints

### 1. Geocoding API

#### Forward Geocoding - Tìm tọa độ từ địa chỉ

**Endpoint:** `GET /geocode/search`

**Parameters:**
- `q` (required): Địa chỉ cần tìm
- `format` (optional): Format trả về (json, xml). Default: json
- `limit` (optional): Số kết quả tối đa. Default: 10
- `countrycodes` (optional): Giới hạn theo mã quốc gia (vn cho Việt Nam)

**Example:**
```bash
curl "http://localhost/geocode/search?q=Hồ+Gươm+Hà+Nội&format=json&limit=5"
```

**Response:**
```json
[
  {
    "place_id": 123456,
    "licence": "Data © OpenStreetMap contributors, ODbL 1.0",
    "osm_type": "way",
    "osm_id": 12345678,
    "boundingbox": ["21.028", "21.029", "105.852", "105.853"],
    "lat": "21.0285",
    "lon": "105.8542",
    "display_name": "Hồ Hoàn Kiếm, Phường Hàng Trống, Quận Hoàn Kiếm, Hà Nội, Việt Nam",
    "class": "natural",
    "type": "water",
    "importance": 0.8
  }
]
```

#### Reverse Geocoding - Tìm địa chỉ từ tọa độ

**Endpoint:** `GET /geocode/reverse`

**Parameters:**
- `lat` (required): Vĩ độ
- `lon` (required): Kinh độ
- `format` (optional): Format trả về. Default: json
- `zoom` (optional): Level chi tiết (0-18). Default: 18

**Example:**
```bash
curl "http://localhost/geocode/reverse?lat=21.0285&lon=105.8542&format=json"
```

**Response:**
```json
{
  "place_id": 123456,
  "licence": "Data © OpenStreetMap contributors, ODbL 1.0",
  "osm_type": "way",
  "osm_id": 12345678,
  "lat": "21.0285",
  "lon": "105.8542",
  "display_name": "Hồ Hoàn Kiếm, Phường Hàng Trống, Quận Hoàn Kiếm, Hà Nội, Việt Nam",
  "address": {
    "water": "Hồ Hoàn Kiếm",
    "suburb": "Phường Hàng Trống",
    "city_district": "Quận Hoàn Kiếm",
    "city": "Hà Nội",
    "country": "Việt Nam",
    "country_code": "vn"
  }
}
```

### 2. Routing API (OSRM)

#### Get Route - Tìm đường giữa 2 điểm

**Endpoint:** `GET /route/v1/driving/{coordinates}`

**Coordinates format:** `lon1,lat1;lon2,lat2;...`

**Parameters:**
- `overview` (optional): Level chi tiết geometry (full, simplified, false). Default: simplified
- `steps` (optional): Include turn-by-turn instructions. Default: false
- `geometries` (optional): Format geometry (polyline, geojson). Default: polyline
- `annotations` (optional): Metadata (duration, distance, speed)

**Example:**
```bash
# Tìm đường từ Hà Nội đến TP.HCM
curl "http://localhost/route/v1/driving/105.8342,21.0278;106.6297,10.8231?overview=full&steps=true&geometries=geojson"
```

**Response:**
```json
{
  "code": "Ok",
  "routes": [
    {
      "distance": 1713542.5,
      "duration": 61687.3,
      "geometry": {
        "type": "LineString",
        "coordinates": [[105.8342, 21.0278], ...]
      },
      "legs": [
        {
          "distance": 1713542.5,
          "duration": 61687.3,
          "steps": [
            {
              "distance": 245.3,
              "duration": 58.9,
              "geometry": {...},
              "name": "Phố Huế",
              "mode": "driving",
              "maneuver": {
                "type": "depart",
                "location": [105.8342, 21.0278]
              }
            }
          ]
        }
      ]
    }
  ],
  "waypoints": [...]
}
```

#### Distance Matrix - Ma trận khoảng cách

**Endpoint:** `GET /route/v1/table/{coordinates}`

**Parameters:**
- `sources` (optional): Index của điểm xuất phát (0;1;2). Default: all
- `destinations` (optional): Index của điểm đến. Default: all
- `annotations` (optional): Metadata cần trả về (duration, distance)

**Example:**
```bash
# Ma trận khoảng cách giữa 3 thành phố
curl "http://localhost/route/v1/table/105.8342,21.0278;106.6297,10.8231;108.2022,16.0544?annotations=distance,duration"
```

**Response:**
```json
{
  "code": "Ok",
  "durations": [
    [0, 61687.3, 41234.5],
    [61687.3, 0, 32456.7],
    [41234.5, 32456.7, 0]
  ],
  "distances": [
    [0, 1713542.5, 1145678.2],
    [1713542.5, 0, 901234.5],
    [1145678.2, 901234.5, 0]
  ],
  "sources": [...],
  "destinations": [...]
}
```

#### Route Optimization - Trip

**Endpoint:** `GET /route/v1/trip/{coordinates}`

**Parameters:**
- `roundtrip` (optional): Quay về điểm đầu. Default: true
- `source` (optional): Điểm bắt đầu (any, first). Default: any
- `destination` (optional): Điểm kết thúc (any, last). Default: any

**Example:**
```bash
# Tối ưu hóa tuyến đi qua 5 điểm
curl "http://localhost/route/v1/trip/105.8342,21.0278;105.8442,21.0378;105.8542,21.0478;105.8642,21.0578;105.8742,21.0678?source=first&destination=last&roundtrip=false"
```

**Response:**
```json
{
  "code": "Ok",
  "trips": [
    {
      "distance": 12345.6,
      "duration": 1234.5,
      "geometry": {...},
      "legs": [...]
    }
  ],
  "waypoints": [...]
}
```

#### Nearest Road - Snap to road

**Endpoint:** `GET /route/v1/nearest/{coordinates}`

**Parameters:**
- `number` (optional): Số kết quả trả về. Default: 1

**Example:**
```bash
curl "http://localhost/route/v1/nearest/105.8342,21.0278?number=3"
```

#### Match - Map matching

**Endpoint:** `GET /route/v1/match/{coordinates}`

**Parameters:**
- `steps` (optional): Include instructions. Default: false
- `geometries` (optional): Format geometry
- `overview` (optional): Level chi tiết

**Example:**
```bash
# Match GPS traces lên đường
curl "http://localhost/route/v1/match/105.8342,21.0278;105.8352,21.0288;105.8362,21.0298?steps=true&geometries=geojson"
```

### 3. Tile Server API

#### Get Map Tiles

**Endpoint:** `GET /tiles/{style}/{z}/{x}/{y}.{format}`

**Parameters:**
- `style`: Map style (basic, osm-bright)
- `z`: Zoom level (0-18)
- `x`, `y`: Tile coordinates
- `format`: png, jpg, webp

**Example:**
```bash
# Lấy tile zoom 10, x=850, y=525
curl "http://localhost/tiles/osm-bright/10/850/525.png"
```

### 4. Vector Tiles API

**Endpoint:** `GET /vector/{table}/{z}/{x}/{y}.pbf`

**Example:**
```bash
curl "http://localhost/vector/roads/10/850/525.pbf"
```

## Error Codes

### HTTP Status Codes

- `200 OK`: Success
- `400 Bad Request`: Invalid parameters
- `404 Not Found`: Resource not found
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

### OSRM Error Codes

- `Ok`: Request successful
- `NoRoute`: No route found
- `NoSegment`: One of the supplied coordinates could not be snapped to street segment
- `InvalidQuery`: Query string is invalid

## Rate Limiting

Default rate limits (có thể thay đổi trong nginx config):

- Geocoding: 60 requests/minute
- Routing: 60 requests/minute
- Tiles: 120 requests/minute

**Response Headers:**
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1234567890
```

## Best Practices

### Geocoding
1. Cache kết quả để giảm số lượng requests
2. Sử dụng `countrycodes=vn` để giới hạn kết quả trong Việt Nam
3. Giới hạn `limit` để tăng tốc độ

### Routing
1. Sử dụng `geometries=geojson` cho web apps
2. Bật `steps=true` chỉ khi cần chỉ dẫn chi tiết
3. Cache routes phổ biến

### Tiles
1. Sử dụng CDN cho production
2. Set proper cache headers
3. Use WebP format for better compression

## Code Examples

### JavaScript/TypeScript

```typescript
// Geocoding
const geocode = async (address: string) => {
  const response = await fetch(
    `http://localhost/geocode/search?q=${encodeURIComponent(address)}&format=json&limit=1`
  )
  const data = await response.json()
  return { lat: parseFloat(data[0].lat), lon: parseFloat(data[0].lon) }
}

// Routing
const getRoute = async (from: [number, number], to: [number, number]) => {
  const coords = `${from[0]},${from[1]};${to[0]},${to[1]}`
  const response = await fetch(
    `http://localhost/route/v1/driving/${coords}?overview=full&geometries=geojson`
  )
  return await response.json()
}
```

### Python

```python
import requests

# Geocoding
def geocode(address):
    url = f"http://localhost/geocode/search"
    params = {"q": address, "format": "json", "limit": 1}
    response = requests.get(url, params=params)
    data = response.json()
    return {"lat": float(data[0]["lat"]), "lon": float(data[0]["lon"])}

# Routing
def get_route(from_coords, to_coords):
    coords = f"{from_coords[0]},{from_coords[1]};{to_coords[0]},{to_coords[1]}"
    url = f"http://localhost/route/v1/driving/{coords}"
    params = {"overview": "full", "geometries": "geojson"}
    response = requests.get(url, params=params)
    return response.json()
```

### cURL Examples

```bash
# Geocoding với nhiều tham số
curl -X GET "http://localhost/geocode/search" \
  -G \
  -d "q=Hồ Hoàn Kiếm, Hà Nội" \
  -d "format=json" \
  -d "limit=5" \
  -d "countrycodes=vn"

# Routing với steps
curl -X GET "http://localhost/route/v1/driving/105.8342,21.0278;106.6297,10.8231" \
  -G \
  -d "overview=full" \
  -d "steps=true" \
  -d "geometries=geojson" \
  -d "annotations=distance,duration"

# Distance matrix
curl -X GET "http://localhost/route/v1/table/105.8342,21.0278;106.6297,10.8231;108.2022,16.0544" \
  -G \
  -d "annotations=distance,duration"
```

## Support

Để biết thêm thông tin:
- [OSRM API Documentation](http://project-osrm.org/docs/v5.24.0/api/)
- [Nominatim API Documentation](https://nominatim.org/release-docs/latest/api/)
- [MapLibre GL JS Documentation](https://maplibre.org/maplibre-gl-js-docs/api/)
