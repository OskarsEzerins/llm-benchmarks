import { FileCode } from 'lucide-react'
import { Card, CardContent } from './ui/card'
import { Badge } from './ui/badge'
import { Checkbox } from './ui/checkbox'
import { normalizeModelName, getModelFamily } from '../lib/model-name-utils'
import { formatLabel } from '../lib/utils'
import type { ImplementationEntry } from '../types/benchmark'

interface ImplementationCardProps {
  implementation: ImplementationEntry
  isSelected: boolean
  onToggleCompare: (implementation: ImplementationEntry) => void
  compareDisabled: boolean
}

export const ImplementationCard = ({
  implementation,
  isSelected,
  onToggleCompare,
  compareDisabled,
}: ImplementationCardProps) => {
  const { type, task, model, lines } = implementation

  return (
    <Card className="group border shadow-sm hover:shadow-md transition-shadow">
      <CardContent className="p-4 space-y-3">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0 flex-1">
            <h3 className="font-medium text-sm truncate" title={normalizeModelName(model)}>
              {normalizeModelName(model)}
            </h3>
            <p className="text-xs text-muted-foreground truncate">
              {getModelFamily(model)}
            </p>
          </div>
          <div
            className="flex items-center"
            onClick={(e: React.MouseEvent) => e.stopPropagation()}
          >
            <Checkbox
              checked={isSelected}
              onCheckedChange={() => onToggleCompare(implementation)}
              disabled={compareDisabled && !isSelected}
              aria-label={`Select ${normalizeModelName(model)} for comparison`}
            />
          </div>
        </div>

        <div className="flex flex-wrap gap-1.5">
          <Badge variant="outline" className="text-xs">
            {formatLabel(type)}
          </Badge>
          <Badge variant="secondary" className="text-xs">
            {formatLabel(task)}
          </Badge>
          <Badge variant="outline" className="text-xs text-muted-foreground">
            <FileCode className="h-3 w-3 mr-1" />
            {lines} lines
          </Badge>
        </div>
      </CardContent>
    </Card>
  )
}
