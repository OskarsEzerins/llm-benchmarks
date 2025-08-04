import { Target, Zap, TrendingUp } from 'lucide-react'

interface HomeStatsDisplayProps {
  stats: {
    totalBenchmarks: number
    totalModels: number
    avgSuccessRate: number
  }
}

export const HomeStatsDisplay = ({ stats }: HomeStatsDisplayProps) => (
  <div className="flex items-center justify-center gap-8 text-sm text-muted-foreground">
    <div className="flex items-center gap-2">
      <Target className="h-4 w-4" />
      <span>{stats.totalBenchmarks} Benchmarks</span>
    </div>
    <div className="flex items-center gap-2">
      <Zap className="h-4 w-4" />
      <span>{stats.totalModels} AI Models</span>
    </div>
    <div className="flex items-center gap-2">
      <TrendingUp className="h-4 w-4" />
      <span>{(stats.avgSuccessRate * 100).toFixed(1)}% Avg Success</span>
    </div>
  </div>
)
