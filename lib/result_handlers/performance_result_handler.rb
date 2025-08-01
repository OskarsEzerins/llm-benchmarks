# frozen_string_literal: true

require_relative 'base_result_handler'

module ResultHandlers
  class PerformanceResultHandler < BaseResultHandler
    MAX_BENCHMARK_RUN_TIME_SECONDS = 5
    MIN_BENCHMARK_RUN_TIME_SECONDS = 0.0001
    MAX_RUBOCOP_OFFENSES = 50

    def calculate_implementation_metrics(impl_results)
      metrics = calculate_average_metrics(impl_results)
      rubocop_offenses = impl_results.filter_map { |r| r['metrics']['rubocop_offenses'] }.max || 0

      best_time = impl_results.filter_map { |r| r['metrics']['execution_time'] }.min || 0
      avg_time = metrics['execution_time'] || 0

      # Calculate scores
      best_time_score = normalize_inverse_score(best_time, MIN_BENCHMARK_RUN_TIME_SECONDS,
                                                MAX_BENCHMARK_RUN_TIME_SECONDS)
      avg_time_score = normalize_inverse_score(avg_time, MIN_BENCHMARK_RUN_TIME_SECONDS, MAX_BENCHMARK_RUN_TIME_SECONDS)
      quality_score = normalize_inverse_score(rubocop_offenses, 0, MAX_RUBOCOP_OFFENSES)

      # Weight the scores (performance benchmarks: time is most important)
      final_score = ((best_time_score * 0.4) + (avg_time_score * 0.3) + (quality_score * 0.3)).round(2)

      {
        'run_count' => impl_results.size,
        'metrics' => metrics,
        'rubocop_offenses' => rubocop_offenses,
        'score' => final_score,
        'score_breakdown' => {
          'best_time_score' => best_time_score.round(2),
          'avg_time_score' => avg_time_score.round(2),
          'quality_score' => quality_score.round(2)
        }
      }
    end

    def calculate_best_results_by_implementation(results)
      results.group_by { |r| r['implementation'] }
             .map { |_, impl_results| select_best_result(impl_results) }
             .compact
             .sort_by { |r| r['metrics']['execution_time'] || Float::INFINITY }
    end

    private

    def select_best_result(impl_results)
      impl_results.min_by { |r| r['metrics']['execution_time'] || Float::INFINITY }
    end

    def normalize_inverse_score(value, min_val, max_val)
      return 100 if max_val == min_val

      range = max_val - min_val
      100 - (((value - min_val) / range) * 100)
    end
  end
end
