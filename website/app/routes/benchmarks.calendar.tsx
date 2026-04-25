import type { Route } from "./+types/benchmarks.calendar";
import { loadBenchmarkData, getBenchmarkRankings, calculateBenchmarkStats } from '../lib/data';
import { BenchmarkPageLayout, BenchmarkPageContent } from '../components/benchmark-page-layout'
import { BenchmarkPageHeader } from '../components/benchmark-page-header'
import { RankingsTable } from '../components/rankings-table'
import { Calendar } from 'lucide-react';

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Calendar System Benchmark - Ruby LLM benchmarks" },
    { name: "description", content: "Detailed analysis of LLM performance on the Calendar System program fixing benchmark" },
  ];
}

export async function loader({ request }: Route.LoaderArgs) {
  const data = await loadBenchmarkData('calendar', request);
  if (!data) {
    throw new Error('Failed to load calendar benchmark data');
  }

  const rankings = getBenchmarkRankings(data);
  const stats = calculateBenchmarkStats(data);

  return {
    rankings,
    stats,
  };
}

export default function CalendarBenchmark({ loaderData }: Route.ComponentProps) {
  const { rankings, stats } = loaderData;

  return (
    <BenchmarkPageLayout
      header={
        <BenchmarkPageHeader
          icon={<Calendar className="h-8 w-8" />}
          title="Calendar System"
          benchmarkType="calendar"
          stats={stats}
        />
      }
    >
      <BenchmarkPageContent>
        <section>
          <RankingsTable data={rankings} showStats={false} />
        </section>
      </BenchmarkPageContent>
    </BenchmarkPageLayout>
  );
}
