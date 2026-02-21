import { useState, useEffect } from 'react'

/**
 * Reactively tracks whether a CSS media query matches.
 * SSR-safe: always returns false until client-side hydration,
 * then syncs immediately via useEffect.
 */
export const useMediaQuery = (query: string): boolean => {
  const [matches, setMatches] = useState(false)

  useEffect(() => {
    const mql = window.matchMedia(query)
    setMatches(mql.matches)

    const onChange = (e: MediaQueryListEvent) => setMatches(e.matches)
    mql.addEventListener('change', onChange)
    return () => mql.removeEventListener('change', onChange)
  }, [query])

  return matches
}
