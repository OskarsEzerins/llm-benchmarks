import type { BenchmarkData, BenchmarkType } from '../types/benchmark';
import { BENCHMARK_NAMES } from '../types/benchmark';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { Progress } from './ui/progress';
import { Calendar, Car, BookOpen, Coffee, TrendingUp, Users, ArrowRight } from 'lucide-react';
import { Link } from 'react-router';
import { getDifficultyLabel, getDifficultyVariant, getDifficultyColor } from '../lib/difficulty-utils';

interface BenchmarkSummaryCardProps {
  benchmarkType: BenchmarkType;
  data: BenchmarkData;
}

export function BenchmarkSummaryCard({ benchmarkType, data }: BenchmarkSummaryCardProps) {
  const getBenchmarkIcon = (type: BenchmarkType) => {
    const icons = {
      calendar: <Calendar className="h-5 w-5" />,
      parking_garage: <Car className="h-5 w-5" />,
      school_library: <BookOpen className="h-5 w-5" />,
      vending_machine: <Coffee className="h-5 w-5" />
    };
    return icons[type];
  };

  const calculateStats = () => {
    const aggregates = Object.values(data.aggregates);
    const totalModels = aggregates.length;
    const avgSuccessRate = aggregates.reduce((sum, agg) => sum + agg.metrics.success_rate, 0) / totalModels;
    const avgQualityScore = aggregates.reduce((sum, agg) => sum + agg.score_breakdown.quality_score, 0) / totalModels;
    const topScore = Math.max(...aggregates.map(agg => agg.score));

    return {
      totalModels,
      avgSuccessRate: avgSuccessRate * 100,
      avgQualityScore,
      topScore
    };
  };

  const stats = calculateStats();
  const benchmarkName = BENCHMARK_NAMES[benchmarkType];

  const getBenchmarkPath = (type: BenchmarkType) => {
    const paths = {
      calendar: '/benchmarks/calendar',
      parking_garage: '/benchmarks/parking-garage',
      school_library: '/benchmarks/school-library',
      vending_machine: '/benchmarks/vending-machine'
    };
    return paths[type];
  };

  return (
    <Link to={getBenchmarkPath(benchmarkType)} className="block group">
      <Card className="group-hover:shadow-2xl transition-all duration-300 shadow-lg cursor-pointer group-hover:translate-x-2 group-hover:translate-y-2 active:translate-x-4 active:translate-y-4 active:shadow-md border-2 border-border bg-card group-hover:bg-accent/50">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-primary/10 border-2 border-primary/20 text-primary group-hover:bg-primary/20 group-hover:scale-110 transition-all duration-300 group-hover:shadow-lg group-hover:border-primary/40">
                {getBenchmarkIcon(benchmarkType)}
              </div>
              <div>
                <CardTitle className="text-lg group-hover:text-primary transition-colors duration-300 font-bold uppercase tracking-wide">
                  {benchmarkName}
                </CardTitle>
                <div className="flex items-center gap-2 mt-1">
                  <Badge variant={getDifficultyVariant(stats.avgSuccessRate)} className="text-xs group-hover:scale-105 transition-transform">
                    {getDifficultyLabel(stats.avgSuccessRate)}
                  </Badge>
                  <span className="text-xs text-muted-foreground">
                    {stats.totalModels} models tested
                  </span>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <div className={`text-2xl font-bold ${getDifficultyColor(stats.avgSuccessRate)} group-hover:scale-110 transition-transform duration-300`}>
                {stats.topScore.toFixed(1)}
              </div>
              <ArrowRight className="h-5 w-5 text-muted-foreground group-hover:text-primary group-hover:translate-x-2 group-hover:scale-110 transition-all duration-300" />
            </div>
          </div>
        </CardHeader>

        <CardContent className="space-y-4">
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Average Success Rate</span>
              <span className="font-medium text-foreground group-hover:font-semibold transition-all">
                {stats.avgSuccessRate.toFixed(1)}%
              </span>
            </div>
            <Progress
              value={stats.avgSuccessRate}
              className="h-2 group-hover:h-3 transition-all duration-300"
            />
          </div>

          <div className="grid grid-cols-2 gap-4 pt-2">
            <div className="space-y-1">
              <div className="flex items-center gap-1">
                <TrendingUp className="h-3 w-3 text-muted-foreground group-hover:text-primary transition-colors group-hover:scale-110" />
                <span className="text-xs text-muted-foreground">Quality Score</span>
              </div>
              <div className="text-lg font-bold text-foreground group-hover:text-primary transition-colors">
                {stats.avgQualityScore.toFixed(0)}
              </div>
            </div>

            <div className="space-y-1">
              <div className="flex items-center gap-1">
                <Users className="h-3 w-3 text-muted-foreground group-hover:text-primary transition-colors group-hover:scale-110" />
                <span className="text-xs text-muted-foreground">Models</span>
              </div>
              <div className="text-lg font-bold text-foreground group-hover:text-primary transition-colors">
                {stats.totalModels}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
