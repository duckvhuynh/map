'use client'

import dynamic from 'next/dynamic'
import { Suspense } from 'react'

const MapComponent = dynamic(() => import('../components/Map'), {
  ssr: false,
  loading: () => (
    <div className="flex items-center justify-center h-screen">
      <div className="text-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-500 mx-auto"></div>
        <p className="mt-4 text-gray-600">Đang tải bản đồ...</p>
      </div>
    </div>
  ),
})

export default function Home() {
  return (
    <main className="h-screen w-screen">
      <Suspense fallback={<div>Loading...</div>}>
        <MapComponent />
      </Suspense>
    </main>
  )
}
