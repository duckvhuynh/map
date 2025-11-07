/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  env: {
    NEXT_PUBLIC_TILE_URL: process.env.NEXT_PUBLIC_TILE_URL || '/tiles',
    NEXT_PUBLIC_ROUTING_URL: process.env.NEXT_PUBLIC_ROUTING_URL || '/route',
    NEXT_PUBLIC_GEOCODING_URL: process.env.NEXT_PUBLIC_GEOCODING_URL || '/geocode',
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || '',
  },
  async rewrites() {
    return [
      // Tile server proxy
      {
        source: '/tiles/:path*',
        destination: 'http://tileserver:8080/styles/osm-bright/:path*',
      },
      // Vector tiles proxy
      {
        source: '/vector/:path*',
        destination: 'http://martin:3000/:path*',
      },
      // Geocoding proxy
      {
        source: '/geocode',
        destination: 'http://nominatim:8080/search',
      },
      // Reverse geocoding proxy
      {
        source: '/reverse',
        destination: 'http://nominatim:8080/reverse',
      },
      // Routing proxies
      {
        source: '/route/car/:path*',
        destination: 'http://osrm-car:5000/:path*',
      },
      {
        source: '/route/bike/:path*',
        destination: 'http://osrm-bike:5000/:path*',
      },
      {
        source: '/route/foot/:path*',
        destination: 'http://osrm-foot:5000/:path*',
      },
      {
        source: '/route/:path*',
        destination: 'http://osrm-car:5000/:path*',
      },
    ]
  },
}

module.exports = nextConfig
