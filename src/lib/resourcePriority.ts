/**
 * Resource Priority Manager
 * Intelligently preloads critical resources for instant page loads
 */

/**
 * Preload critical images
 */
export function preloadCriticalImages() {
  // Game-only images are loaded by the game screen when they are actually
  // needed. Preloading them from the landing route wastes bandwidth and can
  // delay login/home on slower devices.
}

/**
 * Prefetch next likely pages based on current route
 */
export function prefetchLikelyPages(currentPath: string) {
  if (typeof window === 'undefined') return

  const prefetchMap: Record<string, string[]> = {
    '/': ['/login', '/register'],
    '/login': ['/home'],
    '/register': ['/home'],
    '/home': ['/play', '/achievements'],
    '/play': ['/room/create', '/room/join'],
    '/achievements': ['/home'],
  }

  const pagesToPrefetch = prefetchMap[currentPath] || []

  pagesToPrefetch.forEach(path => {
    const link = document.createElement('link')
    link.rel = 'prefetch'
    link.href = path
    document.head.appendChild(link)
  })
}

/**
 * Preconnect to external services
 */
export function preconnectExternalServices() {
  if (typeof window === 'undefined') return

  const services = [
    process.env.NEXT_PUBLIC_SUPABASE_URL,
  ].filter(Boolean) as string[]

  services.forEach(url => {
    // DNS Prefetch
    const dnsPrefetch = document.createElement('link')
    dnsPrefetch.rel = 'dns-prefetch'
    dnsPrefetch.href = url
    document.head.appendChild(dnsPrefetch)

    // Preconnect
    const preconnect = document.createElement('link')
    preconnect.rel = 'preconnect'
    preconnect.href = url
    preconnect.crossOrigin = 'anonymous'
    document.head.appendChild(preconnect)
  })
}

/**
 * Priority hints for fetch requests
 */
export function fetchWithPriority(
  url: string,
  options: RequestInit = {},
  priority: 'high' | 'low' | 'auto' = 'auto'
): Promise<Response> {
  const fetchOptions: RequestInit = {
    ...options,
    // @ts-ignore - Priority is experimental but supported in Chrome
    priority,
  }

  return fetch(url, fetchOptions)
}

/**
 * Preload data for a specific route
 */
export async function preloadRouteData(route: string) {
  // Implement route-specific data preloading
  switch (route) {
    case '/home':
      // Preload profile and achievements
      if (typeof window !== 'undefined') {
        const { createClient } = await import('./supabase/client')
        const supabase = createClient()
        
        // Fire and forget - results will be cached
        void supabase.auth.getUser()
        void supabase.from('user_achievements').select('*').limit(4)
      }
      break

    case '/play':
      // Preload rooms list
      if (typeof window !== 'undefined') {
        const { createClient } = await import('./supabase/client')
        const supabase = createClient()
        
        void supabase.from('rooms').select('*').eq('status', 'waiting').limit(10)
      }
      break

    case '/achievements':
      // Preload all achievements
      if (typeof window !== 'undefined') {
        const { createClient } = await import('./supabase/client')
        const supabase = createClient()
        
        void supabase.from('achievements').select('*')
      }
      break
  }
}

/**
 * Initialize all resource optimizations
 */
export function initializeResourceOptimizations(currentPath: string) {
  if (typeof window === 'undefined') return

  // Wait for page to be interactive
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      runOptimizations(currentPath)
    })
  } else {
    runOptimizations(currentPath)
  }
}

function runOptimizations(currentPath: string) {
  // Run after a short delay to not block main thread
  requestIdleCallback(() => {
    prefetchLikelyPages(currentPath)
    preconnectExternalServices()
  }, { timeout: 2000 })
}

/**
 * Polyfill for requestIdleCallback
 */
const requestIdleCallback =
  typeof window !== 'undefined' && 'requestIdleCallback' in window
    ? window.requestIdleCallback
    : (cb: IdleRequestCallback, options?: IdleRequestOptions) => {
        const start = Date.now()
        return setTimeout(() => {
          cb({
            didTimeout: false,
            timeRemaining: () => Math.max(0, 50 - (Date.now() - start)),
          })
        }, options?.timeout || 1)
      }
