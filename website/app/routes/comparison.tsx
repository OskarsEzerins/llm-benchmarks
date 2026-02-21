import { useState, useMemo, useCallback, useEffect } from 'react'
import type { Route } from './+types/comparison'
import { GitCompareArrows, Database, Layers, FolderTree, Filter } from 'lucide-react'
import { PageLayout, PageContent } from '../components/page-layout'
import { Badge } from '../components/ui/badge'
import { Button } from '../components/ui/button'
import { ImplementationFilters } from '../components/implementation-filters'
import { ImplementationCard } from '../components/implementation-card'
import { CompareToolbar } from '../components/compare-toolbar'
import {
  loadImplementationsManifest,
  filterImplementations,
  getAvailableTypes,
  getAvailableTasks,
  getAvailableFamilies,
} from '../lib/implementations-data'
import type { ImplementationEntry } from '../types/benchmark'
import { useCompareSelections } from '../lib/use-compare-selections'

const DEFAULT_TYPE = 'program_fixer'
const DEFAULT_TASK = 'calendar'
const SEARCH_DEBOUNCE_MS = 300

const writeStorage = (key: string, value: string) => {
  if (typeof window === 'undefined') return
  sessionStorage.setItem(key, value)
}

export function meta() {
  return [
    { title: "Model Comparison - Ruby LLM Benchmarks" },
    { name: "description", content: "Select and compare AI-generated Ruby implementations side by side" },
  ]
}

export async function loader({ request }: Route.LoaderArgs) {
  const manifest = await loadImplementationsManifest(request)
  if (!manifest) {
    throw new Error('Failed to load implementations manifest')
  }
  return { implementations: manifest.implementations }
}

const MAX_COMPARE = 2 as const

export default function Comparison({ loaderData }: Route.ComponentProps) {
  const { implementations } = loaderData
  const [showFilters, setShowFilters] = useState(false)

  const [selectedType, setSelectedType] = useState(DEFAULT_TYPE)
  const [selectedTask, setSelectedTask] = useState(DEFAULT_TASK)
  const [selectedFamily, setSelectedFamily] = useState('all')
  const [searchInput, setSearchInput] = useState('')
  const [searchTerm, setSearchTerm] = useState('')

  const { selections: compareSelections, toggle: toggleCompare, clear: clearCompare, isSelected } = useCompareSelections()

  // Restore filter state from sessionStorage after client hydration
  useEffect(() => {
    const type = sessionStorage.getItem('impl_filter_type')
    const task = sessionStorage.getItem('impl_filter_task')
    const family = sessionStorage.getItem('impl_filter_family')
    const search = sessionStorage.getItem('impl_filter_search')
    if (type) setSelectedType(type)
    if (task) setSelectedTask(task)
    if (family) setSelectedFamily(family)
    if (search) { setSearchInput(search); setSearchTerm(search) }
  }, [])

  // Debounce search input -> searchTerm
  useEffect(() => {
    const timer = setTimeout(() => {
      setSearchTerm(searchInput)
      writeStorage('impl_filter_search', searchInput)
    }, SEARCH_DEBOUNCE_MS)
    return () => clearTimeout(timer)
  }, [searchInput])

  const hasActiveFilters = selectedType !== DEFAULT_TYPE || selectedTask !== DEFAULT_TASK || selectedFamily !== 'all' || searchTerm !== ''

  const clearFilters = useCallback(() => {
    setSelectedType(DEFAULT_TYPE)
    setSelectedTask(DEFAULT_TASK)
    setSelectedFamily('all')
    setSearchInput('')
    setSearchTerm('')
    writeStorage('impl_filter_type', DEFAULT_TYPE)
    writeStorage('impl_filter_task', DEFAULT_TASK)
    writeStorage('impl_filter_family', 'all')
    writeStorage('impl_filter_search', '')
  }, [])

  const handleTypeChange = useCallback((v: string) => {
    setSelectedType(v)
    writeStorage('impl_filter_type', v)
    // Reset task when type changes
    setSelectedTask(DEFAULT_TASK)
    writeStorage('impl_filter_task', DEFAULT_TASK)
  }, [])

  const handleTaskChange = useCallback((v: string) => {
    setSelectedTask(v)
    writeStorage('impl_filter_task', v)
  }, [])

  const handleFamilyChange = useCallback((v: string) => {
    setSelectedFamily(v)
    writeStorage('impl_filter_family', v)
  }, [])

  const handleSearchChange = useCallback((v: string) => {
    setSearchInput(v)
    // writeStorage is called in the debounce effect
  }, [])

  const types = useMemo(() => getAvailableTypes(implementations), [implementations])
  const tasks = useMemo(
    () => getAvailableTasks(implementations, selectedType !== 'all' ? selectedType : undefined),
    [implementations, selectedType]
  )
  const families = useMemo(() => getAvailableFamilies(implementations), [implementations])

  const filtered = useMemo(
    () => filterImplementations(implementations, {
      type: selectedType !== 'all' ? selectedType : undefined,
      task: selectedTask !== 'all' ? selectedTask : undefined,
      family: selectedFamily !== 'all' ? selectedFamily : undefined,
      search: searchTerm || undefined,
    }),
    [implementations, selectedType, selectedTask, selectedFamily, searchTerm]
  )

  const uniqueTypes = useMemo(() => new Set(implementations.map(i => i.type)).size, [implementations])
  const uniqueTasks = useMemo(() => new Set(implementations.map(i => i.task)).size, [implementations])

  return (
    <PageLayout>
      {/* Hero */}
      <div className="border-b-4 border-border bg-background shadow-2xl">
        <div className="container mx-auto px-4 py-12 sm:py-16 max-w-7xl">
          <div className="text-center max-w-4xl mx-auto">
            <div className="flex items-center justify-center gap-3 mb-4">
              <GitCompareArrows className="h-8 w-8 text-primary" />
              <h1 className="text-3xl sm:text-4xl font-bold">Model Comparison</h1>
            </div>
            <p className="text-lg text-muted-foreground mb-6">
              Select two implementations of the same task to compare them side by side
            </p>
            <div className="flex flex-wrap justify-center gap-4 text-sm">
              <div className="flex items-center gap-1.5">
                <Database className="h-4 w-4 text-muted-foreground" />
                <span className="font-semibold">{implementations.length}</span>
                <span className="text-muted-foreground">implementations</span>
              </div>
              <div className="flex items-center gap-1.5">
                <Layers className="h-4 w-4 text-muted-foreground" />
                <span className="font-semibold">{uniqueTypes}</span>
                <span className="text-muted-foreground">types</span>
              </div>
              <div className="flex items-center gap-1.5">
                <FolderTree className="h-4 w-4 text-muted-foreground" />
                <span className="font-semibold">{uniqueTasks}</span>
                <span className="text-muted-foreground">tasks</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <PageContent>
        {/* Filter bar */}
        <div className="space-y-4">
          {/* Mobile filter toggle */}
          <div className="sm:hidden">
            <Button
              variant="outline"
              onClick={() => setShowFilters(!showFilters)}
              className="w-full justify-between"
            >
              <span className="flex items-center gap-2">
                <Filter className="h-4 w-4" />
                Filters
                {hasActiveFilters && (
                  <Badge variant="secondary" className="text-xs">Active</Badge>
                )}
              </span>
            </Button>
          </div>

          {/* Filters (always visible on desktop, toggle on mobile) */}
          <div className={`${showFilters ? 'block' : 'hidden'} sm:block`}>
            <ImplementationFilters
              types={types}
              tasks={tasks}
              families={families}
              selectedType={selectedType}
              selectedTask={selectedTask}
              selectedFamily={selectedFamily}
              searchTerm={searchInput}
              onTypeChange={handleTypeChange}
              onTaskChange={handleTaskChange}
              onFamilyChange={handleFamilyChange}
              onSearchChange={handleSearchChange}
              onClear={clearFilters}
              hasActiveFilters={hasActiveFilters}
            />
          </div>

          <div className="text-sm text-muted-foreground">
            Showing {filtered.length} of {implementations.length} implementations
          </div>
        </div>

        {/* Results grid */}
        {filtered.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {filtered.map((impl) => (
              <ImplementationCard
                key={`${impl.type}/${impl.task}/${impl.model}`}
                implementation={impl}
                isSelected={isSelected(impl)}
                onToggleCompare={toggleCompare}
                compareDisabled={compareSelections.length >= MAX_COMPARE}
              />
            ))}
          </div>
        ) : (
          <div className="text-center py-16 text-muted-foreground">
            <GitCompareArrows className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p className="text-lg">No implementations found</p>
            <p className="text-sm">Try adjusting your filters</p>
          </div>
        )}
      </PageContent>

      {/* Compare toolbar */}
      <CompareToolbar
        selections={compareSelections}
        onRemove={toggleCompare}
        onClear={clearCompare}
      />

      {/* Spacer when compare toolbar is visible */}
      {compareSelections.length > 0 && <div className="h-16" />}
    </PageLayout>
  )
}
