import type { ReactNode } from 'react'
import { Badge } from './ui/badge'
import { StatsGrid } from './StatsGrid'
import { Breadcrumbs } from './Breadcrumbs'
import { getDifficultyLabelUppercase, getDifficultyVariant, getDifficultyColor } from '../lib/difficulty-utils'

interface BenchmarkPageHeaderProps {
  icon: ReactNode
  title: string
  stats: {
    avgSuccessRate: number
    avgQualityScore: number
    testCompletionStats: {
      avgTestsPassed: number
    }
    totalModels: number
    topScore: number
  }
}

export const BenchmarkPageHeader = ({ icon, title, stats }: BenchmarkPageHeaderProps) => {

  return (
    <div className="border-b bg-white/80 dark:bg-slate-950/80 backdrop-blur-sm">
      <div className="container mx-auto px-4 py-8 max-w-7xl">
        {/* Breadcrumbs */}
        <Breadcrumbs
          showBackButton={true}
          backButtonLabel="Back to Overall Rankings"
          items={[
            { label: "Overall Rankings", href: "/" },
            { label: `${title} Details` }
          ]}
        />

        {/* Title Section */}
        <div className="flex items-center gap-4 mb-6">
          <div className="p-4 rounded-xl bg-gradient-to-r from-blue-500 to-indigo-600 text-white">
            {icon}
          </div>
          <div>
            <div className="mb-2">
              <div className="text-sm text-muted-foreground mb-1">
                Benchmark Detail View
              </div>
              <h1 className="text-4xl font-bold text-foreground">
                {title}
              </h1>
            </div>
            <div className="flex items-center gap-3">
              <Badge
                variant={getDifficultyVariant(stats.avgSuccessRate)}
                className="text-sm font-bold px-3 py-1 uppercase"
              >
                {getDifficultyLabelUppercase(stats.avgSuccessRate)} Challenge
              </Badge>
              <span className="text-muted-foreground">
                {stats.totalModels} models tested
              </span>
              <span className={`font-semibold ${getDifficultyColor(stats.avgSuccessRate)}`}>
                Top Score: {stats.topScore.toFixed(1)}
              </span>
            </div>
          </div>
        </div>

        {/* Key Statistics */}
        <StatsGrid stats={stats} />
      </div>
    </div>
  )
}
