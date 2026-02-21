import type { ModelRanking } from '../types/benchmark';
import { getDisplayName, getModelFamily } from '../lib/model-names';
import { Card, CardContent, CardHeader } from './ui/card';
import { Badge } from './ui/badge';
import { Progress } from './ui/progress';
import { Trophy, Target, CheckCircle2, AlertTriangle } from 'lucide-react';

interface ModelRankingCardProps {
  model: ModelRanking;
  rank: number;
  showRank?: boolean;
}

export function ModelRankingCard({ model, rank, showRank = true }: ModelRankingCardProps) {
  const family = getModelFamily(model.implementation);
  const formattedName = getDisplayName(model.implementation);

  const getScoreColor = (score: number) => {
    if (score >= 75) return 'text-emerald-600 dark:text-emerald-400';
    if (score >= 60) return 'text-amber-600 dark:text-amber-400';
    return 'text-red-600 dark:text-red-400';
  };

  const getBadgeVariant = (family: string): "default" | "secondary" | "destructive" | "outline" => {
    const variants = {
      'Claude': 'secondary' as const,
      'OpenAI': 'default' as const,
      'Google': 'outline' as const,
      'DeepSeek': 'secondary' as const,
      'xAI': 'outline' as const,
      'Meta': 'secondary' as const,
      'Other': 'outline' as const
    };
    return variants[family as keyof typeof variants] || 'outline';
  };

  const getRankIcon = (rank: number) => {
    if (rank === 1) return <Trophy className="h-5 w-5 text-yellow-500" />;
    if (rank <= 3) return <Trophy className="h-5 w-5 text-gray-400" />;
    return null;
  };

  const successRate = model.success_rate * 100;

  return (
    <Card className="group hover:shadow-2xl transition-all duration-200 hover:translate-x-2 hover:translate-y-2 shadow-lg border-2 border-border bg-card hover:bg-accent/50">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            {showRank && (
              <div className="flex items-center gap-2">
                {getRankIcon(rank)}
                <span className="text-2xl font-black text-muted-foreground">
                  #{rank}
                </span>
              </div>
            )}
            <Badge variant={getBadgeVariant(family)} className="text-xs">
              {family}
            </Badge>
          </div>
          <div className={`text-3xl font-black ${getScoreColor(model.score)}`}>
            {model.score.toFixed(1)}
          </div>
        </div>
        <h3 className="font-bold uppercase tracking-wide text-foreground text-base leading-tight mt-2 group-hover:text-primary transition-colors">
          {formattedName}
        </h3>
      </CardHeader>

      <CardContent className="space-y-4">
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Target className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm text-muted-foreground">Success Rate</span>
            </div>
            <span className="font-semibold text-foreground">
              {successRate.toFixed(1)}%
            </span>
          </div>
          <Progress
            value={successRate}
            className="h-2"
          />
        </div>

        <div className="grid grid-cols-3 gap-3 pt-2">
          <div className="text-center space-y-1">
            <div className="flex items-center justify-center">
              <CheckCircle2 className="h-4 w-4 text-emerald-500" />
            </div>
            <div className="text-lg font-bold text-foreground">
              {model.tests_passed}
            </div>
            <div className="text-xs text-muted-foreground">
              Tests Passed
            </div>
          </div>

          <div className="text-center space-y-1">
            <div className="flex items-center justify-center">
              <span className="text-muted-foreground font-medium">Q</span>
            </div>
            <div className="text-lg font-bold text-foreground">
              {model.quality_score.toFixed(0)}
            </div>
            <div className="text-xs text-muted-foreground">
              Quality
            </div>
          </div>

          <div className="text-center space-y-1">
            <div className="flex items-center justify-center">
              <AlertTriangle className="h-4 w-4 text-amber-500" />
            </div>
            <div className="text-lg font-bold text-foreground">
              {model.rubocop_offenses}
            </div>
            <div className="text-xs text-muted-foreground">
              Issues
            </div>
          </div>
        </div>

        <div className="text-xs text-muted-foreground text-center pt-2 border-t">
          {model.total_tests} total tests
        </div>
      </CardContent>
    </Card>
  );
}
