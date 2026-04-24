import { Badge } from './ui/badge'
import { getParamSummary } from '../lib/model-names'
import type { ImplementationMetadata } from '../types/benchmark'

interface ModelParameterBadgesProps {
  metadata?: ImplementationMetadata
  className?: string
}

export function ModelParameterBadges({ metadata, className = '' }: ModelParameterBadgesProps) {
  const summary = getParamSummary(metadata)
  if (summary.length === 0) return null

  return (
    <div className={`flex flex-wrap gap-1.5 ${className}`.trim()}>
      {summary.map((item) => (
        <Badge key={item} variant="outline" className="text-[10px] px-1.5 py-0.5">
          {item}
        </Badge>
      ))}
    </div>
  )
}
