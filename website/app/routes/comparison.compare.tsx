import { useMemo } from 'react'
import { Link, useSearchParams, useNavigate } from 'react-router'
import type { Route } from './+types/comparison.compare'
import { ArrowLeft, GitCompareArrows } from 'lucide-react'
import { PageLayout } from '../components/page-layout'
import { Breadcrumbs } from '../components/breadcrumbs'
import { Button } from '../components/ui/button'
import { CompareColumns } from '../components/compare-columns'
import { ComparisonControls } from '../components/comparison-controls'
import { loadImplementationsManifest } from '../lib/implementations-data'
import { itemDisplayName } from '../lib/model-names'
import type { CompareItem, ImplementationEntry } from '../types/benchmark'

export function meta() {
  return [
    { title: "Compare Implementations - Ruby LLM Benchmarks" },
    { name: "description", content: "Side-by-side diff of AI-generated Ruby implementations" },
  ]
}

export async function loader({ request }: Route.LoaderArgs) {
  const manifest = await loadImplementationsManifest(request)
  return {
    allImplementations: manifest?.implementations ?? [] as ImplementationEntry[],
  }
}

const parseItems = (itemsParam: string | null, allImplementations: ImplementationEntry[]): CompareItem[] => {
  if (!itemsParam) return []
  const result: CompareItem[] = []
  for (const item of itemsParam.split(',')) {
    const parts = item.split('/')
    if (parts.length < 3) continue
    const type = parts[0]
    const task = parts[1]
    const model = parts.slice(2).join('/')
    const entry = allImplementations.find(i => i.type === type && i.task === task && i.model === model)
    const compareItem: CompareItem = { type, task, model }
    if (entry?.display_name) compareItem.display_name = entry.display_name
    result.push(compareItem)
  }
  return result
}

export default function ComparisonCompare({ loaderData }: Route.ComponentProps) {
  const { allImplementations } = loaderData
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const items = useMemo(() => parseItems(searchParams.get('items'), allImplementations), [searchParams, allImplementations])

  if (items.length === 0) {
    return (
      <PageLayout>
        <div className="container mx-auto px-4 py-8 max-w-7xl">
          <div className="text-center py-16">
            <GitCompareArrows className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
            <h1 className="text-2xl font-bold mb-2">No Implementations Selected</h1>
            <p className="text-muted-foreground mb-6">
              Select two implementations of the same task to compare them side by side.
            </p>
            <Button asChild>
              <Link to="/comparison">Browse Implementations</Link>
            </Button>
          </div>
        </div>
      </PageLayout>
    )
  }

  const handleItemsChange = (newItems: CompareItem[]) => {
    const encoded = newItems.map(i => `${i.type}/${i.task}/${i.model}`).join(',')
    // Sync selections back to sessionStorage so the catalog page stays consistent
    const entries = newItems.map(i => {
      const impl = allImplementations.find(e => e.type === i.type && e.task === i.task && e.model === i.model)
      return {
        type: i.type,
        task: i.task,
        model: i.model,
        lines: impl?.lines ?? 0,
        display_name: impl?.display_name ?? itemDisplayName(i),
      }
    })
    sessionStorage.setItem('impl_compare_selections', JSON.stringify(entries))
    navigate(`/comparison/compare?items=${encodeURIComponent(encoded)}`)
  }

  return (
    <PageLayout>
      <div className="container mx-auto px-4 py-8 max-w-7xl space-y-6">
        <Breadcrumbs
          items={[
            { label: 'Comparison', href: '/comparison' },
            { label: 'Compare' },
          ]}
        />

        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-bold">Compare Implementations</h1>
            <p className="text-muted-foreground mt-1">
              Comparing {items.length} implementation{items.length !== 1 ? 's' : ''} side by side
            </p>
          </div>
          <Button variant="outline" size="sm" asChild>
            <Link to="/comparison">
              <ArrowLeft className="h-4 w-4 mr-1.5" />
              Back to Comparison
            </Link>
          </Button>
        </div>

        <ComparisonControls
          items={items}
          allImplementations={allImplementations}
          onItemsChange={handleItemsChange}
        />

        <div className="-mx-4 sm:-mx-0">
          <CompareColumns items={items} />
        </div>
      </div>
    </PageLayout>
  )
}
