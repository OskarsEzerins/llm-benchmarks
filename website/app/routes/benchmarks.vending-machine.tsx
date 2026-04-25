import type { Route } from "./+types/benchmarks.vending-machine";
import { loadBenchmarkData, getBenchmarkRankings, calculateBenchmarkStats } from '../lib/data';
import { BenchmarkPageLayout, BenchmarkPageContent } from '../components/benchmark-page-layout'
import { BenchmarkPageHeader } from '../components/benchmark-page-header'
import { RankingsTable } from '../components/rankings-table'
import { Coffee } from 'lucide-react';

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Vending Machine Benchmark - Ruby LLM benchmarks" },
    { name: "description", content: "Detailed analysis of LLM performance on the Vending Machine System program fixing benchmark" },
  ];
}

export async function loader({ request }: Route.LoaderArgs) {
  const data = await loadBenchmarkData('vending_machine', request);
  if (!data) {
    throw new Error('Failed to load vending machine benchmark data');
  }

  const rankings = getBenchmarkRankings(data);
  const stats = calculateBenchmarkStats(data);

  return {
    rankings,
    stats,
  };
}

export default function VendingMachineBenchmark({ loaderData }: Route.ComponentProps) {
  const { rankings, stats } = loaderData;

  return (
    <BenchmarkPageLayout
      header={
        <BenchmarkPageHeader
          icon={<Coffee className="h-8 w-8" />}
          title="Vending Machine System"
          benchmarkType="vending_machine"
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
