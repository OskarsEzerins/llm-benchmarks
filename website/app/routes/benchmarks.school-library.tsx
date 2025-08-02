import type { Route } from "./+types/benchmarks.school-library";
import { loadBenchmarkData, getBenchmarkRankings, calculateBenchmarkStats } from '../lib/data';
import { BenchmarkPageLayout, BenchmarkPageContent } from '../components/BenchmarkPageLayout';
import { BenchmarkPageHeader } from '../components/BenchmarkPageHeader';
import { TopPerformerSection } from '../components/TopPerformerSection';
import { DataTable } from '../components/DataTable';
import { CallToActionSection } from '../components/CallToActionSection';
import { Separator } from '../components/ui/separator';
import { BookOpen } from 'lucide-react';

export function meta({}: Route.MetaArgs) {
  return [
    { title: "School Library Benchmark - Ruby LLM benchmarks" },
    { name: "description", content: "Detailed analysis of LLM performance on the School Library Management System program fixing benchmark" },
  ];
}

export async function loader({ request }: Route.LoaderArgs) {
  const data = await loadBenchmarkData('school_library', request);
  if (!data) {
    throw new Error('Failed to load school library benchmark data');
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

export default function SchoolLibraryBenchmark({ loaderData }: Route.ComponentProps) {
  const { data, rankings, stats, topModels } = loaderData;

  return (
    <BenchmarkPageLayout
      header={
        <BenchmarkPageHeader
          icon={<BookOpen className="h-8 w-8" />}
          title="School Library Management"
          stats={stats}
        />
      }
    >
      <BenchmarkPageContent>
        {/* Primary Data Table */}
        <section className="mb-12">
          <DataTable
            data={rankings}
            title="School Library Benchmark - Individual Model Results"
          />
        </section>

        <Separator className="my-12" />

        <TopPerformerSection
          topModels={topModels}
          championTitle="School Library Champions"
        />

        <Separator className="my-12" />

        <CallToActionSection />
      </BenchmarkPageContent>
    </BenchmarkPageLayout>
  );
}
