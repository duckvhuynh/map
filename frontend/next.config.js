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
}

module.exports = nextConfig
