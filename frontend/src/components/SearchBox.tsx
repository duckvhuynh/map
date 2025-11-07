'use client'

import { useState, useRef, useEffect } from 'react'
import { MapService } from '../services/mapService'

interface SearchBoxProps {
  mapService: MapService
}

interface SearchResult {
  place_id: number
  lat: string
  lon: string
  display_name: string
  type: string
  importance: number
}

export default function SearchBox({ mapService }: SearchBoxProps) {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<SearchResult[]>([])
  const [isSearching, setIsSearching] = useState(false)
  const [showResults, setShowResults] = useState(false)
  const searchTimeout = useRef<NodeJS.Timeout>()

  useEffect(() => {
    // Debounce search
    if (searchTimeout.current) {
      clearTimeout(searchTimeout.current)
    }

    if (query.length < 3) {
      setResults([])
      setShowResults(false)
      return
    }

    searchTimeout.current = setTimeout(async () => {
      setIsSearching(true)
      try {
        const searchResults = await mapService.geocode(query)
        setResults(searchResults)
        setShowResults(true)
      } catch (error) {
        console.error('Search error:', error)
        setResults([])
      } finally {
        setIsSearching(false)
      }
    }, 500)

    return () => {
      if (searchTimeout.current) {
        clearTimeout(searchTimeout.current)
      }
    }
  }, [query, mapService])

  const handleSelectResult = (result: SearchResult) => {
    const lat = parseFloat(result.lat)
    const lon = parseFloat(result.lon)
    
    mapService.addMarker([lon, lat], result.display_name)
    mapService.flyTo([lon, lat], 15)
    
    setQuery(result.display_name)
    setShowResults(false)
  }

  const handleClear = () => {
    setQuery('')
    setResults([])
    setShowResults(false)
  }

  return (
    <div className="search-box">
      <div className="relative">
        <div className="flex items-center">
          <svg
            className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            />
          </svg>
          <input
            type="text"
            placeholder="Tìm kiếm địa điểm..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="w-full pl-10 pr-10 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          {query && (
            <button
              onClick={handleClear}
              className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
            >
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>

        {isSearching && (
          <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
            <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-500"></div>
          </div>
        )}

        {showResults && results.length > 0 && (
          <div className="absolute top-full mt-2 w-full bg-white border border-gray-300 rounded-md shadow-lg max-h-96 overflow-y-auto z-10">
            {results.map((result) => (
              <div
                key={result.place_id}
                onClick={() => handleSelectResult(result)}
                className="px-4 py-3 hover:bg-gray-100 cursor-pointer border-b border-gray-200 last:border-b-0"
              >
                <div className="font-medium text-gray-900 truncate">
                  {result.display_name.split(',')[0]}
                </div>
                <div className="text-sm text-gray-500 truncate">
                  {result.display_name}
                </div>
              </div>
            ))}
          </div>
        )}

        {showResults && results.length === 0 && !isSearching && query.length >= 3 && (
          <div className="absolute top-full mt-2 w-full bg-white border border-gray-300 rounded-md shadow-lg p-4 z-10">
            <p className="text-gray-500 text-center">Không tìm thấy kết quả</p>
          </div>
        )}
      </div>
    </div>
  )
}
