import type { BenchmarkData, BenchmarkType, ModelRanking, BenchmarkAggregate, BenchmarkResult } from '../types/benchmark'

// Date extraction and formatting utilities
export function extractDateFromImplementation(implementation: string): Date | null {
  // Extract date from pattern like "_openrouter_08_2025" or "_08_2025"
  const dateMatch = implementation.match(/_(\d{2})_(\d{4})$/);
  if (dateMatch) {
    const [, month, year] = dateMatch;
    return new Date(parseInt(year), parseInt(month) - 1, 1);
  }
  return null;
}

export function extractDateFromTimestamp(timestamp: string): Date {
  return new Date(timestamp);
}

export function getDateForModel(implementation: string, timestamp?: string): Date {
  // Try to extract from implementation name first
  const implDate = extractDateFromImplementation(implementation);
  if (implDate) {
    return implDate;
  }
  
  // Fall back to timestamp if available
  if (timestamp) {
    return extractDateFromTimestamp(timestamp);
  }
  
  // Default to current date if no date information available
  return new Date();
}

export function formatDateLocale(date: Date): string {
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  }).format(date);
}

export function formatDateShort(date: Date): string {
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: '2-digit'
  }).format(date);
}

// Server-side data loading using filesystem operations
export const loadBenchmarkData = async (benchmarkType: BenchmarkType): Promise<BenchmarkData | null> => {
  try {
    // Only use filesystem operations on server-side in loaders
    if (typeof window === 'undefined') {
      const { readFile } = await import('fs/promises')
      const { join } = await import('path')
      const filePath = join(process.cwd(), 'public', 'data', `${benchmarkType}.json`)
      const fileContent = await readFile(filePath, 'utf-8')
      return JSON.parse(fileContent) as BenchmarkData
    } else {
      // Client-side fallback using fetch API
      const response = await fetch(`/data/${benchmarkType}.json`)
      if (!response.ok) {
        throw new Error(`Failed to fetch ${benchmarkType} data`)
      }
      return await response.json() as BenchmarkData
    }
  } catch (error) {
    console.error(`Error loading ${benchmarkType} data:`, error)
    return null
  }
}

export const loadAllBenchmarkData = async (): Promise<Record<BenchmarkType, BenchmarkData>> => {
  const benchmarkTypes: BenchmarkType[] = ['calendar', 'parking_garage', 'school_library', 'vending_machine']
  const results: Record<string, BenchmarkData> = {}

  await Promise.all(
    benchmarkTypes.map(async (type) => {
      const data = await loadBenchmarkData(type)
      if (data) {
        results[type] = data
      }
    })
  )

  return results as Record<BenchmarkType, BenchmarkData>
}

export function calculateTotalRankings(allData: Record<BenchmarkType, BenchmarkData>): ModelRanking[] {
  const modelScores: Record<string, {
    totalScore: number;
    benchmarkCount: number;
    totalSuccessRate: number;
    totalQualityScore: number;
    totalTestsPassed: number;
    totalTests: number;
    totalRubocopOffenses: number;
    firstTimestamp?: string;
  }> = {};

  // Aggregate scores across all benchmarks
  Object.values(allData).forEach(benchmarkData => {
    Object.entries(benchmarkData.aggregates).forEach(([implementation, aggregate]) => {
      if (!modelScores[implementation]) {
        modelScores[implementation] = {
          totalScore: 0,
          benchmarkCount: 0,
          totalSuccessRate: 0,
          totalQualityScore: 0,
          totalTestsPassed: 0,
          totalTests: 0,
          totalRubocopOffenses: 0
        };
      }

      const model = modelScores[implementation];
      model.totalScore += aggregate.score;
      model.benchmarkCount += 1;
      model.totalSuccessRate += aggregate.metrics.success_rate;
      model.totalQualityScore += aggregate.score_breakdown.quality_score;
      model.totalTestsPassed += aggregate.metrics.tests_passed;
      model.totalTests += aggregate.metrics.total_tests;
      model.totalRubocopOffenses += aggregate.rubocop_offenses;

      // Get the first timestamp for this implementation
      if (!model.firstTimestamp) {
        const result = benchmarkData.results.find(r => r.implementation === implementation);
        if (result) {
          model.firstTimestamp = result.timestamp;
        }
      }
    });
  });

  // Calculate averages and create rankings
  return Object.entries(modelScores)
    .map(([implementation, scores]) => ({
      implementation,
      score: scores.totalScore / scores.benchmarkCount,
      success_rate: scores.totalSuccessRate / scores.benchmarkCount,
      quality_score: scores.totalQualityScore / scores.benchmarkCount,
      tests_passed: Math.round(scores.totalTestsPassed / scores.benchmarkCount),
      total_tests: Math.round(scores.totalTests / scores.benchmarkCount),
      rubocop_offenses: Math.round(scores.totalRubocopOffenses / scores.benchmarkCount),
      date: getDateForModel(implementation, scores.firstTimestamp)
    }))
    .sort((a, b) => b.score - a.score);
}

export function getBenchmarkRankings(data: BenchmarkData): ModelRanking[] {
  return Object.entries(data.aggregates)
    .map(([implementation, aggregate]) => {
      // Find the first result for this implementation to get timestamp
      const result = data.results.find(r => r.implementation === implementation);
      
      return {
        implementation,
        score: aggregate.score,
        success_rate: aggregate.metrics.success_rate,
        quality_score: aggregate.score_breakdown.quality_score,
        tests_passed: aggregate.metrics.tests_passed,
        total_tests: aggregate.metrics.total_tests,
        rubocop_offenses: aggregate.rubocop_offenses,
        date: getDateForModel(implementation, result?.timestamp)
      };
    })
    .sort((a, b) => b.score - a.score);
}

export function formatModelName(implementation: string): string {
  return implementation
    .replace(/_openrouter_\d+_\d+/g, '')
    .replace(/_/g, ' ')
    .split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

export function getModelFamily(implementation: string): string {
  const name = implementation.toLowerCase();
  if (name.includes('claude')) return 'Claude';
  if (name.includes('openai') || name.includes('gpt')) return 'OpenAI';
  if (name.includes('gemini')) return 'Google';
  if (name.includes('deepseek')) return 'DeepSeek';
  if (name.includes('grok')) return 'xAI';
  if (name.includes('llama')) return 'Meta';
  if (name.includes('mistral')) return 'Mistral';
  if (name.includes('qwen')) return 'Alibaba';
  if (name.includes('nova')) return 'Amazon';
  return 'Other';
}

export function calculateBenchmarkStats(data: BenchmarkData) {
  const aggregates = Object.values(data.aggregates);
  const totalModels = aggregates.length;

  if (totalModels === 0) {
    return {
      totalModels: 0,
      avgSuccessRate: 0,
      avgQualityScore: 0,
      topScore: 0,
      successRateDistribution: { easy: 0, medium: 0, hard: 0 },
      modelFamilyStats: {},
      testCompletionStats: { avgTestsPassed: 0, avgTotalTests: 0 },
      qualityDistribution: { excellent: 0, good: 0, poor: 0 }
    };
  }

  const avgSuccessRate = aggregates.reduce((sum, agg) => sum + agg.metrics.success_rate, 0) / totalModels;
  const avgQualityScore = aggregates.reduce((sum, agg) => sum + agg.score_breakdown.quality_score, 0) / totalModels;
  const topScore = Math.max(...aggregates.map(agg => agg.score));

  // Success rate distribution
  const successRateDistribution = aggregates.reduce((dist, agg) => {
    const rate = agg.metrics.success_rate * 100;
    if (rate >= 70) dist.easy++;
    else if (rate >= 50) dist.medium++;
    else dist.hard++;
    return dist;
  }, { easy: 0, medium: 0, hard: 0 });

  // Model family statistics
  const modelFamilyStats: Record<string, { count: number; avgScore: number; avgSuccessRate: number }> = {};

  Object.entries(data.aggregates).forEach(([implementation, aggregate]) => {
    const family = getModelFamily(implementation);
    if (!modelFamilyStats[family]) {
      modelFamilyStats[family] = { count: 0, avgScore: 0, avgSuccessRate: 0 };
    }
    modelFamilyStats[family].count++;
    modelFamilyStats[family].avgScore += aggregate.score;
    modelFamilyStats[family].avgSuccessRate += aggregate.metrics.success_rate;
  });

  // Calculate averages for model families
  Object.keys(modelFamilyStats).forEach(family => {
    const stats = modelFamilyStats[family];
    stats.avgScore /= stats.count;
    stats.avgSuccessRate /= stats.count;
  });

  // Test completion statistics
  const avgTestsPassed = aggregates.reduce((sum, agg) => sum + agg.metrics.tests_passed, 0) / totalModels;
  const avgTotalTests = aggregates.reduce((sum, agg) => sum + agg.metrics.total_tests, 0) / totalModels;

  // Quality distribution
  const qualityDistribution = aggregates.reduce((dist, agg) => {
    const quality = agg.score_breakdown.quality_score;
    if (quality >= 85) dist.excellent++;
    else if (quality >= 70) dist.good++;
    else dist.poor++;
    return dist;
  }, { excellent: 0, good: 0, poor: 0 });

  return {
    totalModels,
    avgSuccessRate: avgSuccessRate * 100,
    avgQualityScore,
    topScore,
    successRateDistribution,
    modelFamilyStats,
    testCompletionStats: { avgTestsPassed, avgTotalTests },
    qualityDistribution
  };
}

export function mergeRankingsAcrossBenchmarks(benchmarkRankings: ModelRanking[][]): ModelRanking[] {
  const modelScores: Record<string, {
    totalScore: number;
    benchmarkCount: number;
    totalSuccessRate: number;
    totalQualityScore: number;
    totalTestsPassed: number;
    totalTests: number;
    totalRubocopOffenses: number;
    firstDate?: Date;
  }> = {};

  // Aggregate scores across all benchmark rankings
  benchmarkRankings.forEach(rankings => {
    rankings.forEach(ranking => {
      if (!modelScores[ranking.implementation]) {
        modelScores[ranking.implementation] = {
          totalScore: 0,
          benchmarkCount: 0,
          totalSuccessRate: 0,
          totalQualityScore: 0,
          totalTestsPassed: 0,
          totalTests: 0,
          totalRubocopOffenses: 0
        };
      }

      const model = modelScores[ranking.implementation];
      model.totalScore += ranking.score;
      model.benchmarkCount += 1;
      model.totalSuccessRate += ranking.success_rate;
      model.totalQualityScore += ranking.quality_score;
      model.totalTestsPassed += ranking.tests_passed;
      model.totalTests += ranking.total_tests;
      model.totalRubocopOffenses += ranking.rubocop_offenses;
      
      // Keep the first date we encounter for this model
      if (!model.firstDate) {
        model.firstDate = ranking.date;
      }
    });
  });

  // Calculate averages and create merged rankings
  return Object.entries(modelScores)
    .map(([implementation, scores]) => ({
      implementation,
      score: scores.totalScore / scores.benchmarkCount,
      success_rate: scores.totalSuccessRate / scores.benchmarkCount,
      quality_score: scores.totalQualityScore / scores.benchmarkCount,
      tests_passed: Math.round(scores.totalTestsPassed / scores.benchmarkCount),
      total_tests: Math.round(scores.totalTests / scores.benchmarkCount),
      rubocop_offenses: Math.round(scores.totalRubocopOffenses / scores.benchmarkCount),
      date: scores.firstDate || getDateForModel(implementation)
    }))
    .sort((a, b) => b.score - a.score);
}
