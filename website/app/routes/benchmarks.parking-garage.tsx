import type { Route } from "./+types/benchmarks.parking-garage";
import { loadBenchmarkData, getBenchmarkRankings, calculateBenchmarkStats } from '../lib/data';
import { BenchmarkPageLayout, BenchmarkPageContent } from '../components/benchmark-page-layout';
import { BenchmarkPageHeader } from '../components/benchmark-page-header';
import { RankingsTable } from '../components/rankings-table';
import { Car } from 'lucide-react';

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Parking Garage Benchmark - Ruby LLM benchmarks" },
    { name: "description", content: "Detailed analysis of LLM performance on the Parking Garage Management System program fixing benchmark" },
  ];
}

export async function loader({ request }: Route.LoaderArgs) {
  const data = await loadBenchmarkData('parking_garage', request);
  if (!data) {
    throw new Error('Failed to load parking garage benchmark data');
  }

  const rankings = getBenchmarkRankings(data);
  const stats = calculateBenchmarkStats(data);

  return {
    rankings,
    stats,
  };
}

export default function ParkingGarageBenchmark({ loaderData }: Route.ComponentProps) {
  const { rankings, stats } = loaderData;

  return (
    <BenchmarkPageLayout
      header={
        <BenchmarkPageHeader
          icon={<Car className="h-8 w-8" />}
          title="Parking Garage Management"
          benchmarkType="parking_garage"
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
