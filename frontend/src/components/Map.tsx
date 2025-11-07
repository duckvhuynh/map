'use client'

import { useEffect, useRef, useState } from 'react'
import maplibregl from 'maplibre-gl'
import { MapService } from '../services/mapService'
import SearchBox from './SearchBox'
import RoutePanel from './RoutePanel'

export default function Map() {
  const mapContainer = useRef<HTMLDivElement>(null)
  const map = useRef<maplibregl.Map | null>(null)
  const [mapService, setMapService] = useState<MapService | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!mapContainer.current || map.current) return

    try {
      // Initialize map
      const newMap = new maplibregl.Map({
        container: mapContainer.current,
        style: {
          version: 8,
          sources: {
            'vietnam-raster': {
              type: 'raster',
              tiles: [
                '/tiles/{z}/{x}/{y}.png'
              ],
              tileSize: 256,
              attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors | Vietnam Map Server'
            },
            'vietnam-vector': {
              type: 'vector',
              tiles: [
                '/vector/{z}/{x}/{y}.pbf'
              ],
              minzoom: 0,
              maxzoom: 14
            }
          },
          layers: [
            {
              id: 'vietnam-raster',
              type: 'raster',
              source: 'vietnam-raster',
              minzoom: 0,
              maxzoom: 18
            }
          ]
        },
        center: [108.2772, 14.0583], // Vietnam center
        zoom: 6,
        attributionControl: true
      })

      // Add navigation controls
      newMap.addControl(new maplibregl.NavigationControl(), 'top-left')
      newMap.addControl(new maplibregl.GeolocateControl({
        positionOptions: {
          enableHighAccuracy: true
        },
        trackUserLocation: true
      }), 'top-left')
      newMap.addControl(new maplibregl.ScaleControl({}), 'bottom-left')
      newMap.addControl(new maplibregl.FullscreenControl(), 'top-left')

      newMap.on('load', () => {
        console.log('Map loaded successfully')
        setIsLoading(false)
      })

      newMap.on('error', (e) => {
        console.error('Map error:', e)
        setError('Lỗi khi tải bản đồ')
      })

      map.current = newMap
      setMapService(new MapService(newMap))

    } catch (err) {
      console.error('Error initializing map:', err)
      setError('Không thể khởi tạo bản đồ')
      setIsLoading(false)
    }

    return () => {
      if (map.current) {
        map.current.remove()
      }
    }
  }, [])

  return (
    <div className="relative w-full h-full">
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-white bg-opacity-90 z-50">
          <div className="text-center">
            <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-4 text-gray-600">Đang tải bản đồ Việt Nam...</p>
          </div>
        </div>
      )}
      
      {error && (
        <div className="absolute top-4 left-1/2 transform -translate-x-1/2 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded z-50">
          <strong className="font-bold">Lỗi!</strong>
          <span className="block sm:inline"> {error}</span>
        </div>
      )}

      <div ref={mapContainer} className="w-full h-full" />
      
      {mapService && (
        <>
          <SearchBox mapService={mapService} />
          <RoutePanel mapService={mapService} />
        </>
      )}

      {/* Info panel */}
      <div className="absolute bottom-4 left-4 bg-white p-3 rounded shadow-lg text-sm max-w-xs">
        <h3 className="font-bold text-gray-800 mb-2">Vietnam Map Server</h3>
        <p className="text-gray-600 text-xs">
          Hệ thống bản đồ mở cho Việt Nam
        </p>
        <div className="mt-2 text-xs text-gray-500">
          <div>🗺️ Tiles: OpenStreetMap</div>
          <div>🚗 Routing: OSRM</div>
          <div>📍 Geocoding: Nominatim</div>
        </div>
      </div>
    </div>
  )
}
