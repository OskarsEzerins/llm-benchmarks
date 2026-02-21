import { useState, useEffect, useCallback } from 'react'
import type { ImplementationEntry } from '../types/benchmark'

const KEY = 'impl_compare_selections'
const MAX = 2

export const useCompareSelections = () => {
  const [selections, setSelections] = useState<ImplementationEntry[]>([])

  // Restore from sessionStorage on mount
  useEffect(() => {
    try {
      const stored = sessionStorage.getItem(KEY)
      if (stored) {
        const parsed: unknown = JSON.parse(stored)
        if (Array.isArray(parsed)) setSelections(parsed as ImplementationEntry[])
      }
    } catch {
      // ignore malformed storage
    }
  }, [])

  const persist = useCallback((next: ImplementationEntry[]) => {
    if (typeof window !== 'undefined') {
      sessionStorage.setItem(KEY, JSON.stringify(next))
    }
    setSelections(next)
  }, [])

  const toggle = useCallback((impl: ImplementationEntry) => {
    setSelections(prev => {
      const key = `${impl.type}/${impl.task}/${impl.model}`
      const exists = prev.some(s => `${s.type}/${s.task}/${s.model}` === key)
      let next: ImplementationEntry[]
      if (exists) {
        next = prev.filter(s => `${s.type}/${s.task}/${s.model}` !== key)
      } else if (prev.length >= MAX) {
        return prev
      } else {
        next = [...prev, impl]
      }
      sessionStorage.setItem(KEY, JSON.stringify(next))
      return next
    })
  }, [])

  const clear = useCallback(() => persist([]), [persist])

  const isSelected = useCallback(
    (impl: ImplementationEntry) => {
      const key = `${impl.type}/${impl.task}/${impl.model}`
      return selections.some(s => `${s.type}/${s.task}/${s.model}` === key)
    },
    [selections],
  )

  return { selections, toggle, clear, isSelected, setSelections: persist }
}
