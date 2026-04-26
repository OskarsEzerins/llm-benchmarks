export type ThinkingMode = 'off' | 'adaptive' | 'manual' | 'unknown'
export type ReasoningEffort = 'none' | 'minimal' | 'low' | 'medium' | 'high' | 'xhigh' | 'unknown'

export interface ImplementationMetadata {
  implementation?: string;
  variant_id: string;
  variant_key?: string;
  provider: string;
  family: string;
  base_model_id: string;
  model_id?: string | null;
  base_model_name: string;
  variant_label: string;
  display_name: string;
  implementation_slug_prefix: string;
  legacy_slug_prefixes?: string[];
  source_tag?: string;
  params?: Record<string, unknown>;
  normalized: {
    thinking_mode: ThinkingMode;
    reasoning_effort: ReasoningEffort;
    budget_tokens?: number;
  };
  param_summary: string[];
  configured_variant?: boolean;
}

export interface BenchmarkResult {
  implementation: string;
  timestamp: string;
  implementation_metadata?: ImplementationMetadata;
  metrics: {
    rubocop_offenses: number;
    tests_passed: number;
    total_tests: number;
    success_rate: number;
    primary_metric: number;
    success: boolean;
  };
}

export interface BenchmarkGenerationTiming {
  duration_seconds: number;
  started_at?: string;
  completed_at?: string;
}

export interface ModelGenerationTiming extends BenchmarkGenerationTiming {
  benchmark?: BenchmarkType;
  benchmark_name?: string;
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
  implementations_meta: Record<string, ImplementationMetadata>;
  generation_timings?: Record<string, BenchmarkGenerationTiming>;
}

export interface ModelRanking {
  implementation: string;
  metadata: ImplementationMetadata;
  score: number;
  success_rate: number;
  quality_score: number;
  tests_passed: number;
  total_tests: number;
  rubocop_offenses: number;
  date: Date;
  generation_timings?: ModelGenerationTiming[];
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
  display_name: string;
  provider?: string;
  metadata?: ImplementationMetadata;
}

export interface ImplementationsManifest {
  implementations: ImplementationEntry[];
}

export interface CompareItem {
  type: string;
  task: string;
  model: string;
  display_name?: string;
  metadata?: ImplementationMetadata;
}
