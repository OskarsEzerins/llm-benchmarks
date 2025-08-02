import { Card, CardContent } from './ui/card'
import { Target, TrendingUp, CheckCircle, Users } from 'lucide-react'

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

export const StatsGrid = ({ stats }: StatsGridProps) => (
  <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
    <Card className="shadow-lg border-2 border-emerald-300 dark:border-emerald-700 bg-emerald-50 dark:bg-emerald-950/50 hover:shadow-xl hover:translate-x-1 hover:translate-y-1 transition-all duration-200">
      <CardContent className="pt-4">
        <div className="flex items-center gap-2 mb-2">
          <Target className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
          <span className="text-sm font-bold uppercase tracking-wider text-muted-foreground">Success Rate</span>
        </div>
        <div className="text-3xl font-black text-emerald-600 dark:text-emerald-400">
          {stats.avgSuccessRate.toFixed(1)}%
        </div>
      </CardContent>
    </Card>

    <Card className="shadow-lg border-2 border-blue-300 dark:border-blue-700 bg-blue-50 dark:bg-blue-950/50 hover:shadow-xl hover:translate-x-1 hover:translate-y-1 transition-all duration-200">
      <CardContent className="pt-4">
        <div className="flex items-center gap-2 mb-2">
          <TrendingUp className="h-4 w-4 text-blue-600 dark:text-blue-400" />
          <span className="text-sm font-bold uppercase tracking-wider text-muted-foreground">Quality Score</span>
        </div>
        <div className="text-3xl font-black text-blue-600 dark:text-blue-400">
          {stats.avgQualityScore.toFixed(0)}
        </div>
      </CardContent>
    </Card>

    <Card className="shadow-lg border-2 border-purple-300 dark:border-purple-700 bg-purple-50 dark:bg-purple-950/50 hover:shadow-xl hover:translate-x-1 hover:translate-y-1 transition-all duration-200">
      <CardContent className="pt-4">
        <div className="flex items-center gap-2 mb-2">
          <CheckCircle className="h-4 w-4 text-purple-600 dark:text-purple-400" />
          <span className="text-sm font-bold uppercase tracking-wider text-muted-foreground">Tests Passed</span>
        </div>
        <div className="text-3xl font-black text-purple-600 dark:text-purple-400">
          {stats.testCompletionStats.avgTestsPassed.toFixed(0)}
        </div>
      </CardContent>
    </Card>

    <Card className="shadow-lg border-2 border-amber-300 dark:border-amber-700 bg-amber-50 dark:bg-amber-950/50 hover:shadow-xl hover:translate-x-1 hover:translate-y-1 transition-all duration-200">
      <CardContent className="pt-4">
        <div className="flex items-center gap-2 mb-2">
          <Users className="h-4 w-4 text-amber-600 dark:text-amber-400" />
          <span className="text-sm font-bold uppercase tracking-wider text-muted-foreground">Models Tested</span>
        </div>
        <div className="text-3xl font-black text-amber-600 dark:text-amber-400">
          {stats.totalModels}
        </div>
      </CardContent>
    </Card>
  </div>
)
