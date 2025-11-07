import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Vietnam Map Server',
  description: 'Open source map server for Vietnam with routing, geocoding, and more',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="vi">
      <head>
        <link href='https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css' rel='stylesheet' />
      </head>
      <body>{children}</body>
    </html>
  )
}
