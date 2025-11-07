'use client'

import { useState } from 'react'
import { MapService } from '../services/mapService'

interface RoutePanelProps {
  mapService: MapService
}

export default function RoutePanel({ mapService }: RoutePanelProps) {
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [isCalculating, setIsCalculating] = useState(false)
  const [routeInfo, setRouteInfo] = useState<any>(null)
  const [error, setError] = useState<string | null>(null)

  const handleCalculateRoute = async () => {
    if (!from || !to) {
      setError('Vui lòng nhập điểm đi và điểm đến')
      return
    }

    setIsCalculating(true)
    setError(null)

    try {
      // Geocode from và to addresses
      const fromResults = await mapService.geocode(from)
      const toResults = await mapService.geocode(to)

      if (!fromResults.length || !toResults.length) {
        setError('Không tìm thấy địa chỉ')
        return
      }

      const fromCoords = [parseFloat(fromResults[0].lon), parseFloat(fromResults[0].lat)]
      const toCoords = [parseFloat(toResults[0].lon), parseFloat(toResults[0].lat)]

      // Calculate route
      const route = await mapService.getRoute(fromCoords, toCoords)
      
      if (route && route.routes && route.routes.length > 0) {
        setRouteInfo(route.routes[0])
        mapService.displayRoute(route.routes[0].geometry)
      } else {
        setError('Không tìm thấy tuyến đường')
      }
    } catch (err) {
      console.error('Route calculation error:', err)
      setError('Lỗi khi tính toán tuyến đường')
    } finally {
      setIsCalculating(false)
    }
  }

  const handleClear = () => {
    setFrom('')
    setTo('')
    setRouteInfo(null)
    setError(null)
    mapService.clearRoute()
  }

  const formatDistance = (meters: number) => {
    if (meters < 1000) {
      return `${Math.round(meters)} m`
    }
    return `${(meters / 1000).toFixed(2)} km`
  }

  const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`
    }
    return `${minutes} phút`
  }

  return (
    <div className="route-panel">
      <h3 className="text-lg font-bold mb-4 text-gray-800">Tìm Đường</h3>
      
      <div className="space-y-3">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Điểm đi
          </label>
          <input
            type="text"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            placeholder="Nhập địa chỉ điểm đi..."
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Điểm đến
          </label>
          <input
            type="text"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            placeholder="Nhập địa chỉ điểm đến..."
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="flex gap-2">
          <button
            onClick={handleCalculateRoute}
            disabled={isCalculating || !from || !to}
            className="flex-1 bg-blue-500 text-white px-4 py-2 rounded-md hover:bg-blue-600 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
          >
            {isCalculating ? (
              <span className="flex items-center justify-center">
                <svg className="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Đang tính...
              </span>
            ) : (
              'Tìm đường'
            )}
          </button>
          
          {routeInfo && (
            <button
              onClick={handleClear}
              className="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-100 transition-colors"
            >
              Xóa
            </button>
          )}
        </div>
      </div>

      {error && (
        <div className="mt-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded-md text-sm">
          {error}
        </div>
      )}

      {routeInfo && (
        <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-md">
          <h4 className="font-semibold text-gray-800 mb-3">Thông tin tuyến đường</h4>
          
          <div className="space-y-2 text-sm">
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Khoảng cách:</span>
              <span className="font-semibold text-gray-900">
                {formatDistance(routeInfo.distance)}
              </span>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Thời gian:</span>
              <span className="font-semibold text-gray-900">
                {formatDuration(routeInfo.duration)}
              </span>
            </div>
          </div>

          {routeInfo.legs && routeInfo.legs[0] && routeInfo.legs[0].steps && (
            <div className="mt-4">
              <h5 className="font-semibold text-gray-800 mb-2 text-sm">
                Chỉ dẫn đường đi ({routeInfo.legs[0].steps.length} bước)
              </h5>
              <div className="max-h-64 overflow-y-auto space-y-2">
                {routeInfo.legs[0].steps.map((step: any, index: number) => (
                  <div key={index} className="text-xs bg-white p-2 rounded border border-gray-200">
                    <div className="flex items-start">
                      <span className="flex-shrink-0 w-6 h-6 bg-blue-500 text-white rounded-full flex items-center justify-center text-xs mr-2">
                        {index + 1}
                      </span>
                      <div className="flex-1">
                        <div className="text-gray-900">{step.maneuver?.modifier || 'Đi thẳng'}</div>
                        <div className="text-gray-600 mt-1">
                          {formatDistance(step.distance)} • {formatDuration(step.duration)}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
