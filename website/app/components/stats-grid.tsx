import { cn } from '../lib/utils'

interface StatsGridProps {
  stats: {
    avgSuccessRate: number
    avgQualityScore: number
    testCompletionStats: {
      avgTestsPassed: number
    }
    totalModels: number
  }
}

export const StatsGrid = ({ stats }: StatsGridProps) => {
  const items = [
    { label: 'Success Rate', value: `${stats.avgSuccessRate.toFixed(1)}%`, tone: 'text-[var(--c-score-hi)]' },
    { label: 'Quality Score', value: stats.avgQualityScore.toFixed(0), tone: 'text-[var(--c-fg)]' },
    { label: 'Avg Tests Passed', value: stats.testCompletionStats.avgTestsPassed.toFixed(0), tone: 'text-[var(--c-fg)]' },
    { label: 'Models Tested', value: stats.totalModels, tone: 'text-[var(--c-fg)]' },
  ]

  return (
    <div className="grid border-[3px] border-[var(--c-fg)] bg-[var(--c-surface)] shadow-[4px_4px_0_var(--c-fg)] sm:grid-cols-2 lg:grid-cols-4">
      {items.map((item, index) => (
        <div
          key={item.label}
          className={cn(
            'border-[var(--c-fg)] px-4 py-3 text-center',
            index < 3 ? 'border-b-2' : '',
            index % 2 === 0 ? 'sm:border-r-2' : '',
            index < 2 ? 'sm:border-b-2' : 'sm:border-b-0',
            index < 3 ? 'lg:border-r-2' : 'lg:border-r-0',
            'lg:border-b-0',
          )}
        >
          <div className="mb-1 font-mono text-[10px] font-bold uppercase tracking-[0.1em] text-[var(--c-dim)]">
            {item.label}
          </div>
          <div className={cn('font-mono text-[22px] font-extrabold', item.tone)}>
            {item.value}
          </div>
        </div>
      ))}
    </div>
  )
}
