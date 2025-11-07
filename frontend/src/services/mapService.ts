import maplibregl from 'maplibre-gl'
import axios from 'axios'

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost'
const GEOCODING_URL = process.env.NEXT_PUBLIC_GEOCODING_URL || 'http://localhost:7070'
const ROUTING_URL = process.env.NEXT_PUBLIC_ROUTING_URL || 'http://localhost:5000'

export class MapService {
  private map: maplibregl.Map
  private markers: maplibregl.Marker[] = []
  private routeLayer: string = 'route'

  constructor(map: maplibregl.Map) {
    this.map = map
  }

  // Geocoding - Search for places
  async geocode(query: string): Promise<any[]> {
    try {
      const response = await axios.get(`${API_BASE}/geocode/search`, {
        params: {
          q: query,
          format: 'json',
          limit: 5,
          countrycodes: 'vn', // Limit to Vietnam
        },
      })
      return response.data
    } catch (error) {
      console.error('Geocoding error:', error)
      return []
    }
  }

  // Reverse geocoding - Get address from coordinates
  async reverseGeocode(lat: number, lon: number): Promise<any> {
    try {
      const response = await axios.get(`${API_BASE}/geocode/reverse`, {
        params: {
          lat,
          lon,
          format: 'json',
        },
      })
      return response.data
    } catch (error) {
      console.error('Reverse geocoding error:', error)
      return null
    }
  }

  // Routing - Get route between two points
  async getRoute(from: number[], to: number[]): Promise<any> {
    try {
      const coords = `${from[0]},${from[1]};${to[0]},${to[1]}`
      const response = await axios.get(`${API_BASE}/route/v1/driving/${coords}`, {
        params: {
          overview: 'full',
          steps: true,
          geometries: 'geojson',
        },
      })
      return response.data
    } catch (error) {
      console.error('Routing error:', error)
      return null
    }
  }

  // Distance Matrix
  async getDistanceMatrix(sources: number[][], destinations: number[][]): Promise<any> {
    try {
      const coords = [...sources, ...destinations]
        .map(c => `${c[0]},${c[1]}`)
        .join(';')
      
      const response = await axios.get(`${API_BASE}/route/v1/table/${coords}`, {
        params: {
          sources: sources.map((_, i) => i).join(';'),
          destinations: destinations.map((_, i) => sources.length + i).join(';'),
          annotations: 'distance,duration',
        },
      })
      return response.data
    } catch (error) {
      console.error('Distance matrix error:', error)
      return null
    }
  }

  // Isochrone - Get area reachable within time/distance
  async getIsochrone(center: number[], minutes: number[]): Promise<any> {
    try {
      const coords = `${center[0]},${center[1]}`
      const response = await axios.get(`${API_BASE}/route/v1/isochrone/${coords}`, {
        params: {
          contours_minutes: minutes.join(','),
        },
      })
      return response.data
    } catch (error) {
      console.error('Isochrone error:', error)
      return null
    }
  }

  // Add marker to map
  addMarker(coordinates: number[], label?: string): maplibregl.Marker {
    const marker = new maplibregl.Marker()
      .setLngLat(coordinates as [number, number])
      .addTo(this.map)

    if (label) {
      const popup = new maplibregl.Popup({ offset: 25 })
        .setHTML(`<div style="padding: 5px;">${label}</div>`)
      marker.setPopup(popup)
    }

    this.markers.push(marker)
    return marker
  }

  // Clear all markers
  clearMarkers(): void {
    this.markers.forEach(marker => marker.remove())
    this.markers = []
  }

  // Display route on map
  displayRoute(geometry: any): void {
    // Remove existing route if any
    this.clearRoute()

    // Add route source and layer
    this.map.addSource(this.routeLayer, {
      type: 'geojson',
      data: {
        type: 'Feature',
        properties: {},
        geometry: geometry,
      },
    })

    this.map.addLayer({
      id: this.routeLayer,
      type: 'line',
      source: this.routeLayer,
      layout: {
        'line-join': 'round',
        'line-cap': 'round',
      },
      paint: {
        'line-color': '#0070f3',
        'line-width': 5,
        'line-opacity': 0.8,
      },
    })

    // Fit map to route bounds
    const coordinates = geometry.coordinates
    const bounds = coordinates.reduce(
      (bounds: maplibregl.LngLatBounds, coord: number[]) => {
        return bounds.extend(coord as [number, number])
      },
      new maplibregl.LngLatBounds(coordinates[0], coordinates[0])
    )

    this.map.fitBounds(bounds, {
      padding: 50,
    })
  }

  // Clear route from map
  clearRoute(): void {
    if (this.map.getLayer(this.routeLayer)) {
      this.map.removeLayer(this.routeLayer)
    }
    if (this.map.getSource(this.routeLayer)) {
      this.map.removeSource(this.routeLayer)
    }
  }

  // Fly to location
  flyTo(coordinates: number[], zoom: number = 15): void {
    this.map.flyTo({
      center: coordinates as [number, number],
      zoom: zoom,
      essential: true,
    })
  }

  // Get map bounds
  getBounds(): maplibregl.LngLatBounds {
    return this.map.getBounds()
  }

  // Get map center
  getCenter(): maplibregl.LngLat {
    return this.map.getCenter()
  }

  // Get map zoom
  getZoom(): number {
    return this.map.getZoom()
  }
}
