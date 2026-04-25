import type { Route } from "./+types/benchmarks.school-library";
import { loadBenchmarkData, getBenchmarkRankings, calculateBenchmarkStats } from '../lib/data';
import { BenchmarkPageLayout, BenchmarkPageContent } from '../components/benchmark-page-layout'
import { BenchmarkPageHeader } from '../components/benchmark-page-header'
import { RankingsTable } from '../components/rankings-table'
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
    rankings,
    stats,
  };
}

export default function SchoolLibraryBenchmark({ loaderData }: Route.ComponentProps) {
  const { rankings, stats } = loaderData;

  return (
    <BenchmarkPageLayout
      header={
        <BenchmarkPageHeader
          icon={<BookOpen className="h-8 w-8" />}
          title="School Library Management"
          benchmarkType="school_library"
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
