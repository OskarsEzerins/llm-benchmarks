import type { Route } from "./+types/home";
import type { BenchmarkType } from '../types/benchmark';
import { calculateTotalRankings, loadAllBenchmarkData } from '../lib/data';
import { BenchmarkSummaryCard } from '../components/BenchmarkSummaryCard';
import { PageLayout, PageContent } from '../components/PageLayout';
import { HeroSection } from '../components/HeroSection';
import { HomeStatsDisplay } from '../components/HomeStatsDisplay';
import { TopPerformerSection } from '../components/TopPerformerSection';
import { DataTable } from '../components/DataTable';
import { ScoringExplanation } from '../components/ScoringExplanation';
import { Card, CardContent } from '../components/ui/card';
import { Separator } from '../components/ui/separator';
import { Award, Database, Bot, Target, TrendingUp, Trophy } from 'lucide-react';

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Ruby LLM benchmarks - Overall Model Rankings" },
    { name: "description", content: "Overall rankings and performance analysis of LLM models across all program fixing benchmarks" },
  ];
}

export async function loader({ request }: Route.LoaderArgs) {
  const allData = await loadAllBenchmarkData(request);
  const totalRankings = calculateTotalRankings(allData);

  return {
    allData,
    totalRankings, // All models for data table
    topModels: totalRankings.slice(0, 3), // Top 3 models
    stats: {
      totalModels: totalRankings.length,
      totalBenchmarks: Object.keys(allData).length,
      avgSuccessRate: totalRankings.reduce((sum, model) => sum + model.success_rate, 0) / totalRankings.length,
      avgQualityScore: totalRankings.reduce((sum, model) => sum + model.quality_score, 0) / totalRankings.length
    }
  };
}

export default function Home({ loaderData }: Route.ComponentProps) {
  const { allData, totalRankings, topModels, stats } = loaderData;

  return (
    <PageLayout>
      <HeroSection
        title="Overall Model Rankings"
        subtitle="Comprehensive performance analysis of LLM models across all program fixing benchmarks - testing Ruby code generation capabilities through real programming challenges validated against test suites and RuboCop quality standards"
      >
        <HomeStatsDisplay stats={stats} />
      </HeroSection>

      <PageContent>
        {/* Primary Data Table - Main Focus */}
        <section className="mb-12">
          <DataTable
            data={totalRankings}
            allData={allData}
            title="Overall Performance Rankings - All Benchmarks Combined"
          />
        </section>

        <Separator className="my-12" />
        <section className="mb-12">
          <ScoringExplanation />
        </section>

        <Separator className="my-12" />

        <TopPerformerSection
          topModels={topModels}
          championTitle="Champions"
          useHomeStyle={true}
        />

        <Separator className="my-12" />

        {/* Quick Stats Grid */}
        <section>
          <h2 className="text-3xl font-black uppercase tracking-wider text-foreground mb-8 text-center">
            Performance Overview
          </h2>
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            <Card className="text-center shadow-lg border-2 border-emerald-300 dark:border-emerald-700 bg-emerald-50 dark:bg-emerald-950/50 hover:shadow-xl hover:translate-x-1 hover:translate-y-1 transition-all duration-200">
              <CardContent className="pt-6">
                <div className="flex justify-center mb-3">
                  <Bot className="h-8 w-8 text-emerald-600 dark:text-emerald-400" />
                </div>
                <div className="text-3xl font-black text-emerald-600 dark:text-emerald-400 mb-2">
                  {stats.totalModels}
                </div>
                <div className="text-sm font-bold uppercase tracking-wider text-muted-foreground">
                  AI Models Tested
                </div>
              </CardContent>
            </Card>

            <Card className="text-center shadow-lg border-2 border-blue-300 dark:border-blue-700 bg-blue-50 dark:bg-blue-950/50 hover:shadow-xl hover:translate-x-1 hover:translate-y-1 transition-all duration-200">
              <CardContent className="pt-6">
                <div className="flex justify-center mb-3">
                  <Database className="h-8 w-8 text-blue-600 dark:text-blue-400" />
                </div>
                <div className="text-3xl font-black text-blue-600 dark:text-blue-400 mb-2">
                  {stats.totalBenchmarks}
                </div>
                <div className="text-sm font-bold uppercase tracking-wider text-muted-foreground">
                  Benchmarks
                </div>
              </CardContent>
            </Card>

            <Card className="text-center shadow-lg border-2 border-amber-300 dark:border-amber-700 bg-amber-50 dark:bg-amber-950/50 hover:shadow-xl hover:translate-x-1 hover:translate-y-1 transition-all duration-200">
              <CardContent className="pt-6">
                <div className="flex justify-center mb-3">
                  <Target className="h-8 w-8 text-amber-600 dark:text-amber-400" />
                </div>
                <div className="text-3xl font-black text-amber-600 dark:text-amber-400 mb-2">
                  {(stats.avgSuccessRate * 100).toFixed(1)}%
                </div>
                <div className="text-sm font-bold uppercase tracking-wider text-muted-foreground">
                  Avg Success Rate
                </div>
              </CardContent>
            </Card>

            <Card className="text-center shadow-lg border-2 border-purple-300 dark:border-purple-700 bg-purple-50 dark:bg-purple-950/50 hover:shadow-xl hover:translate-x-1 hover:translate-y-1 transition-all duration-200">
              <CardContent className="pt-6">
                <div className="flex justify-center mb-3">
                  <TrendingUp className="h-8 w-8 text-purple-600 dark:text-purple-400" />
                </div>
                <div className="text-3xl font-black text-purple-600 dark:text-purple-400 mb-2">
                  {stats.avgQualityScore.toFixed(0)}
                </div>
                <div className="text-sm font-bold uppercase tracking-wider text-muted-foreground">
                  Avg Quality Score
                </div>
              </CardContent>
            </Card>
          </div>
        </section>

        <Separator className="my-12" />

        {/* Benchmark Overview */}
        <section>
          <div className="flex items-center gap-3 mb-8">
            <Award className="h-6 w-6 text-blue-500" />
            <h2 className="text-3xl font-black uppercase tracking-wider text-foreground">Benchmark Challenges</h2>
          </div>
          <div className="grid gap-6 sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-4">
            {Object.entries(allData).map(([benchmarkType, data]) => (
              <BenchmarkSummaryCard
                key={benchmarkType}
                benchmarkType={benchmarkType as BenchmarkType}
                data={data}
              />
            ))}
          </div>
        </section>

        {/* Call to Action */}
        <section className="text-center py-12">
          <Card className="max-w-2xl mx-auto border-0 shadow-lg bg-gradient-to-r from-slate-50 to-slate-100 dark:from-slate-800 dark:to-slate-900">
            <CardContent className="pt-8">
              <h3 className="text-2xl font-bold text-foreground mb-4">
                Dive Deeper into the Analysis (coming soon)
              </h3>
              <p className="text-muted-foreground mb-6">
                Explore detailed benchmark results, model comparisons, and performance insights across all coding challenges.
              </p>
            </CardContent>
          </Card>
        </section>
      </PageContent>
    </PageLayout>
  );
}
