import type { ImplementationsManifest, ImplementationEntry, ThinkingMode, ReasoningEffort } from '../types/benchmark'
import { getModelFamily } from './model-names'

export const loadImplementationsManifest = async (request?: Request): Promise<ImplementationsManifest | null> => {
  try {
    let url: string

    if (typeof window === 'undefined' && request) {
      const baseUrl = new URL(request.url).origin
      url = `${baseUrl}/data/implementations.json`
    } else {
      url = `/data/implementations.json`
    }

    const response = await fetch(url)
    if (!response.ok) {
      throw new Error(`Failed to fetch implementations manifest: ${response.status}`)
    }
    return await response.json() as ImplementationsManifest
  } catch (error) {
    console.error('Error loading implementations manifest:', error)
    return null
  }
}

export const loadImplementationSource = async (type: string, task: string, model: string): Promise<string | null> => {
  try {
    const url = `/data/implementations/${type}/${task}/${model}.rb`
    const response = await fetch(url)
    if (!response.ok) {
      throw new Error(`Failed to fetch source: ${response.status}`)
    }
    return await response.text()
  } catch (error) {
    console.error('Error loading implementation source:', error)
    return null
  }
}

export interface ImplementationFilters {
  type?: string
  task?: string
  search?: string
  family?: string
  thinkingMode?: ThinkingMode
  reasoningEffort?: ReasoningEffort
}

export const filterImplementations = (
  implementations: ImplementationEntry[],
  filters: ImplementationFilters
): ImplementationEntry[] => {
  let filtered = implementations

  if (filters.type) {
    filtered = filtered.filter(impl => impl.type === filters.type)
  }

  if (filters.task) {
    filtered = filtered.filter(impl => impl.task === filters.task)
  }

  if (filters.search) {
    const search = filters.search.toLowerCase()
    filtered = filtered.filter(impl =>
      impl.model.toLowerCase().includes(search) ||
      impl.display_name.toLowerCase().includes(search) ||
      impl.metadata?.base_model_name.toLowerCase().includes(search) ||
      impl.metadata?.variant_label.toLowerCase().includes(search) ||
      impl.metadata?.provider.toLowerCase().includes(search) ||
      impl.metadata?.param_summary.some(item => item.toLowerCase().includes(search))
    )
  }

  if (filters.family) {
    filtered = filtered.filter(impl => getModelFamily(impl.metadata) === filters.family)
  }

  if (filters.thinkingMode) {
    filtered = filtered.filter(impl => impl.metadata?.normalized.thinking_mode === filters.thinkingMode)
  }

  if (filters.reasoningEffort) {
    filtered = filtered.filter(impl => impl.metadata?.normalized.reasoning_effort === filters.reasoningEffort)
  }

  return filtered
}

export const getAvailableTypes = (implementations: ImplementationEntry[]): string[] => {
  return [...new Set(implementations.map(impl => impl.type))].sort()
}

export const getAvailableTasks = (implementations: ImplementationEntry[], type?: string): string[] => {
  const filtered = type ? implementations.filter(impl => impl.type === type) : implementations
  return [...new Set(filtered.map(impl => impl.task))].sort()
}

export const getAvailableFamilies = (implementations: ImplementationEntry[]): string[] => {
  return [...new Set(implementations.map(impl => getModelFamily(impl.metadata)))].sort()
}

export const getAvailableThinkingModes = (implementations: ImplementationEntry[]): ThinkingMode[] => {
  return [...new Set(implementations.map(impl => impl.metadata?.normalized.thinking_mode).filter(Boolean))] as ThinkingMode[]
}

export const getAvailableReasoningEfforts = (implementations: ImplementationEntry[]): ReasoningEffort[] => {
  return [...new Set(implementations.map(impl => impl.metadata?.normalized.reasoning_effort).filter(Boolean))] as ReasoningEffort[]
}
