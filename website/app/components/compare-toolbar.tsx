import { Link } from 'react-router'
import { GitCompareArrows, X, AlertTriangle } from 'lucide-react'
import { Button } from './ui/button'
import { itemDisplayName } from '../lib/model-names'
import type { ImplementationEntry } from '../types/benchmark'

interface CompareToolbarProps {
  selections: ImplementationEntry[]
  onRemove: (implementation: ImplementationEntry) => void
  onClear: () => void
}

export const CompareToolbar = ({ selections, onRemove, onClear }: CompareToolbarProps) => {
  if (selections.length === 0) return null

  const compareParams = selections
    .map(s => `${s.type}/${s.task}/${s.model}`)
    .join(',')

  const hasMismatch =
    selections.length === 2 &&
    (selections[0].task !== selections[1].task || selections[0].type !== selections[1].type)

  const canCompare = selections.length === 2 && !hasMismatch

  return (
    <div className="fixed bottom-0 left-0 right-0 z-40 border-t border-border bg-background/95 backdrop-blur-sm">
      <div className="container mx-auto px-4 max-w-7xl h-14 flex items-center gap-3">
        {/* Count label */}
        <span className="text-sm text-muted-foreground whitespace-nowrap shrink-0">
          {selections.length} selected
        </span>

        {/* Chips */}
        <div className="flex items-center gap-2 min-w-0 flex-1 overflow-x-auto">
          {selections.map(s => (
            <span
              key={`${s.type}/${s.task}/${s.model}`}
              className="inline-flex items-center gap-1.5 bg-muted text-foreground text-sm font-medium rounded-full px-3 py-1 shrink-0"
            >
              <span className="truncate max-w-[140px] sm:max-w-[200px]">
                {itemDisplayName(s)}
              </span>
              <button
                onClick={() => onRemove(s)}
                className="text-muted-foreground hover:text-foreground transition-colors ml-0.5 leading-none"
                aria-label={`Remove ${itemDisplayName(s)} from comparison`}
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </span>
          ))}

          {hasMismatch && (
            <span className="inline-flex items-center gap-1 text-xs text-amber-600 dark:text-amber-400 whitespace-nowrap shrink-0">
              <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
              Same task required
            </span>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2 shrink-0">
          <Button variant="ghost" size="sm" onClick={onClear} className="text-muted-foreground hover:text-foreground">
            Clear
          </Button>
          {canCompare ? (
            <Button asChild size="sm">
              <Link to={`/comparison/compare?items=${encodeURIComponent(compareParams)}`}>
                <GitCompareArrows className="h-4 w-4 mr-1.5" />
                Compare
              </Link>
            </Button>
          ) : (
            <Button size="sm" disabled>
              <GitCompareArrows className="h-4 w-4 mr-1.5" />
              Compare ({selections.length}/2)
            </Button>
          )}
        </div>
      </div>
    </div>
  )
}
