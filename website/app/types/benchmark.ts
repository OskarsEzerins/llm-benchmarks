export interface BenchmarkResult {
  implementation: string;
  timestamp: string;
  metrics: {
    rubocop_offenses: number;
    tests_passed: number;
    total_tests: number;
    success_rate: number;
    primary_metric: number;
    success: boolean;
  };
}

export interface BenchmarkAggregate {
  run_count: number;
  metrics: {
    rubocop_offenses: number;
    tests_passed: number;
    total_tests: number;
    success_rate: number;
    primary_metric: number;
    success: number;
  };
  rubocop_offenses: number;
  score: number;
  score_breakdown: {
    success_score: number;
    quality_score: number;
  };
}

export interface BenchmarkData {
  results: BenchmarkResult[];
  aggregates: Record<string, BenchmarkAggregate>;
}

export interface ModelRanking {
  implementation: string;
  score: number;
  success_rate: number;
  quality_score: number;
  tests_passed: number;
  total_tests: number;
  rubocop_offenses: number;
  date: Date;
}

export type BenchmarkType = 'calendar' | 'parking_garage' | 'school_library' | 'vending_machine';

export const BENCHMARK_NAMES: Record<BenchmarkType, string> = {
  calendar: 'Calendar System',
  parking_garage: 'Parking Garage',
  school_library: 'School Library',
  vending_machine: 'Vending Machine'
};

export interface ImplementationEntry {
  type: string;
  task: string;
  model: string;
  lines: number;
}

export interface ImplementationsManifest {
  implementations: ImplementationEntry[];
}

export interface CompareItem {
  type: string;
  task: string;
  model: string;
}
