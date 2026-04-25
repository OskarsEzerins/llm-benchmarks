import type { ReactNode } from 'react'
import { useNavigate } from 'react-router'
import { StatsGrid } from './stats-grid'
import type { BenchmarkType } from '../types/benchmark'
import { BENCHMARK_NAMES } from '../types/benchmark'
import { getDifficultyLabelUppercase } from '../lib/difficulty-utils'

interface BenchmarkPageHeaderProps {
  icon: ReactNode
  title: string
  benchmarkType: BenchmarkType
  stats: {
    avgSuccessRate: number
    avgQualityScore: number
    testCompletionStats: {
      avgTestsPassed: number
    }
    totalModels: number
    topScore: number
  }
}

const benchmarkPaths: Record<BenchmarkType, string> = {
  calendar: '/benchmarks/calendar',
  parking_garage: '/benchmarks/parking-garage',
  school_library: '/benchmarks/school-library',
  vending_machine: '/benchmarks/vending-machine',
}

export const BenchmarkPageHeader = ({ icon, title, benchmarkType, stats }: BenchmarkPageHeaderProps) => {
  const navigate = useNavigate()
  const handleBenchmarkChange = (value: string) => {
    const benchmarkPath = benchmarkPaths[value as BenchmarkType]
    if (benchmarkPath) navigate(benchmarkPath)
  }

  return (
    <div className="border-b-[3px] border-[var(--c-fg)] bg-[var(--c-surface)]">
      <div className="mx-auto max-w-[1080px] px-5 py-8 md:px-8">
        <div className="mb-7 flex flex-col gap-5 md:flex-row md:items-end md:justify-between">
          <div className="flex items-start gap-3">
            <div className="flex h-12 w-12 shrink-0 items-center justify-center border-[3px] border-[var(--c-fg)] bg-[var(--c-accent)] text-white shadow-[3px_3px_0_var(--c-fg)]">
              {icon}
            </div>
            <div>
              <div className="mb-1 font-mono text-[11px] font-bold uppercase tracking-[0.12em] text-[var(--c-dim)]">
                Benchmark Detail
              </div>
              <h1 className="font-sans text-3xl font-extrabold leading-none text-[var(--c-fg)] md:text-5xl">
                {title}
              </h1>
              <div className="mt-3 flex flex-wrap items-center gap-2 font-mono text-[11px] font-bold uppercase tracking-[0.06em]">
                <span className="border-2 border-[var(--c-fg)] bg-[var(--c-surface-2)] px-2 py-1 text-[var(--c-fg)]">
                  {getDifficultyLabelUppercase(stats.avgSuccessRate)}
                </span>
                <span className="text-[var(--c-sub)]">{stats.totalModels} models tested</span>
                <span className="text-[var(--c-score-hi)]">Top {stats.topScore.toFixed(1)}</span>
              </div>
            </div>
          </div>

          <label className="flex w-full flex-col gap-1.5 md:w-[280px]">
            <span className="font-mono text-[10px] font-bold uppercase tracking-[0.1em] text-[var(--c-dim)]">
              Benchmark
            </span>
            <select
              value={benchmarkType}
              onInput={(event) => handleBenchmarkChange(event.currentTarget.value)}
              onChange={(event) => handleBenchmarkChange(event.currentTarget.value)}
              className="w-full border-[3px] border-[var(--c-fg)] bg-[var(--c-surface)] px-3 py-2.5 font-mono text-[12px] font-bold uppercase tracking-[0.05em] text-[var(--c-fg)] shadow-[3px_3px_0_var(--c-fg)] outline-none"
            >
              {(Object.entries(BENCHMARK_NAMES) as [BenchmarkType, string][]).map(([type, name]) => (
                <option key={type} value={type}>
                  {name}
                </option>
              ))}
            </select>
          </label>
        </div>

        <StatsGrid stats={stats} />
      </div>
    </div>
  )
}
