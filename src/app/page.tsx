'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import MagicalBackground from '@/components/ui/MagicalBackground'
import LoadingMagic from '@/components/ui/LoadingMagic'

export default function Home() {
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    // Register service worker for instant loading
    if (process.env.NODE_ENV === 'production') {
      import('@/lib/serviceWorker').then(({ registerServiceWorker }) => {
        registerServiceWorker()
      })
    }
    
    void checkAuth()
  }, []) // eslint-disable-line react-hooks/exhaustive-deps -- redirect is evaluated once on mount

  async function checkAuth() {
    // The server-side route check handles redirects. This client redirect only
    // needs the already-cached browser session, so it should not block on Auth.
    const { data: { session } } = await supabase.auth.getSession()

    if (session?.user) {
      router.replace('/home')
    } else {
      router.replace('/login')
    }
  }

  return (
    <MagicalBackground>
      <LoadingMagic />
    </MagicalBackground>
  )
}
