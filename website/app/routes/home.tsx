import type { Route } from "./+types/home";
import { calculateTotalRankings, loadAllBenchmarkData } from '../lib/data';
import { PageLayout, PageContent } from '../components/page-layout'
import { RankingsTable } from '../components/rankings-table'

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
    totalRankings,
  };
}

export default function Home({ loaderData }: Route.ComponentProps) {
  const { totalRankings } = loaderData;

  return (
    <PageLayout>
      <PageContent>
        <RankingsTable data={totalRankings} />
      </PageContent>
    </PageLayout>
  );
}
