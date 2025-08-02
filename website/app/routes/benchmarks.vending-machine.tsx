import type { Route } from "./+types/benchmarks.vending-machine";
import { loadBenchmarkData, getBenchmarkRankings, calculateBenchmarkStats } from '../lib/data';
import { BenchmarkPageLayout, BenchmarkPageContent } from '../components/BenchmarkPageLayout';
import { BenchmarkPageHeader } from '../components/BenchmarkPageHeader';
import { TopPerformerSection } from '../components/TopPerformerSection';
import { DataTable } from '../components/DataTable';
import { CallToActionSection } from '../components/CallToActionSection';
import { Separator } from '../components/ui/separator';
import { Coffee } from 'lucide-react';

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Vending Machine Benchmark - Ruby LLM benchmarks" },
    { name: "description", content: "Detailed analysis of LLM performance on the Vending Machine System program fixing benchmark" },
  ];
}

export async function loader() {
  const data = await loadBenchmarkData('vending_machine');
  if (!data) {
    throw new Error('Failed to load vending machine benchmark data');
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

export default function VendingMachineBenchmark({ loaderData }: Route.ComponentProps) {
  const { data, rankings, stats, topModels } = loaderData;

  return (
    <BenchmarkPageLayout
      header={
        <BenchmarkPageHeader
          icon={<Coffee className="h-8 w-8" />}
          title="Vending Machine System"
          stats={stats}
        />
      }
    >
      <BenchmarkPageContent>
        {/* Primary Data Table */}
        <section className="mb-12">
          <DataTable
            data={rankings}
            title="Vending Machine Benchmark - Individual Model Results"
          />
        </section>

        <Separator className="my-12" />

        <TopPerformerSection
          topModels={topModels}
          championTitle="Vending Machine Champions"
        />

        <Separator className="my-12" />

        <CallToActionSection />
      </BenchmarkPageContent>
    </BenchmarkPageLayout>
  );
}
