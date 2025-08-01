import type { Route } from "./+types/benchmarks.calendar";
import { loadBenchmarkData, getBenchmarkRankings, calculateBenchmarkStats } from '../lib/data';
import { BenchmarkPageLayout, BenchmarkPageContent } from '../components/BenchmarkPageLayout';
import { BenchmarkPageHeader } from '../components/BenchmarkPageHeader';
import { TopPerformerSection } from '../components/TopPerformerSection';
import { DataTable } from '../components/DataTable';
import { CallToActionSection } from '../components/CallToActionSection';
import { Separator } from '../components/ui/separator';
import { Calendar } from 'lucide-react';

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Calendar System Benchmark - Ruby LLM benchmarks" },
    { name: "description", content: "Detailed analysis of LLM performance on the Calendar System program fixing benchmark" },
  ];
}

export async function loader() {
  const data = await loadBenchmarkData('calendar');
  if (!data) {
    throw new Error('Failed to load calendar benchmark data');
  }

  const rankings = getBenchmarkRankings(data);
  const stats = calculateBenchmarkStats(data);

  return {
    data,
    rankings,
    stats,
    topModels: rankings.slice(0, 3), // Top 3 models
  };
}

export default function CalendarBenchmark({ loaderData }: Route.ComponentProps) {
  const { data, rankings, stats, topModels } = loaderData;

  return (
    <BenchmarkPageLayout
      header={
        <BenchmarkPageHeader
          icon={<Calendar className="h-8 w-8" />}
          title="Calendar System"
          stats={stats}
        />
      }
    >
      <BenchmarkPageContent>
        {/* Primary Data Table */}
        <section className="mb-12">
          <DataTable
            data={rankings}
            title="Calendar System Benchmark - Individual Model Results"
          />
        </section>

        <Separator className="my-12" />

        <TopPerformerSection
          topModels={topModels}
          championTitle="Calendar Challenge Champions"
        />

        <Separator className="my-12" />

        <CallToActionSection />
      </BenchmarkPageContent>
    </BenchmarkPageLayout>
  );
}
