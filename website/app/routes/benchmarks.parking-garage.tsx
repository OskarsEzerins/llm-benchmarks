import type { Route } from "./+types/benchmarks.parking-garage";
import { loadBenchmarkData, getBenchmarkRankings, calculateBenchmarkStats } from '../lib/data';
import { BenchmarkPageLayout, BenchmarkPageContent } from '../components/benchmark-page-layout';
import { BenchmarkPageHeader } from '../components/benchmark-page-header';
import { TopPerformerSection } from '../components/top-performer-section';
import { DataTable } from '../components/data-table';
import { CallToActionSection } from '../components/call-to-action-section';
import { Separator } from '../components/ui/separator';
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
    data,
    rankings,
    stats,
    topModels: rankings.slice(0, 3), // Top 3 models
  };
}

export default function ParkingGarageBenchmark({ loaderData }: Route.ComponentProps) {
  const { data, rankings, stats, topModels } = loaderData;

  return (
    <BenchmarkPageLayout
      header={
        <BenchmarkPageHeader
          icon={<Car className="h-8 w-8" />}
          title="Parking Garage Management"
          stats={stats}
        />
      }
    >
      <BenchmarkPageContent>
        {/* Primary Data Table */}
        <section className="mb-12">
          <DataTable
            data={rankings}
            title="Parking Garage Benchmark - Individual Model Results"
          />
        </section>

        <Separator className="my-12" />

        <TopPerformerSection
          topModels={topModels}
          championTitle="Parking Garage Champions"
        />

        <Separator className="my-12" />

        <CallToActionSection />
      </BenchmarkPageContent>
    </BenchmarkPageLayout>
  );
}
