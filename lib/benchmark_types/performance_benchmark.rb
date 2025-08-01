# frozen_string_literal: true

require_relative 'base_benchmark'

module BenchmarkTypes
  class PerformanceBenchmark < BaseBenchmark
    class << self
      def benchmark_type
        :performance
      end

      def evaluate_result(raw_result)
        execution_time = raw_result.is_a?(Hash) ? raw_result[:execution_time] : raw_result

        {
          execution_time: execution_time,
          primary_metric: execution_time,
          success: execution_time.positive? && execution_time.finite?
        }
      end

      def metric_names
        %w[execution_time primary_metric success]
      end

      def scoring_weight_config
        {
          time_weight: 0.7,
          quality_weight: 0.3
        }
      end

      def calculate_percentage_score(result_data, rubocop_offenses, context_data)
        time_score = calculate_time_score(result_data[:execution_time], context_data)
        quality_score = calculate_quality_score(rubocop_offenses)

        weights = scoring_weight_config
        final_score = (time_score * weights[:time_weight]) +
                      (quality_score * weights[:quality_weight])

        {
          score: final_score.round(2),
          breakdown: {
            time_score: time_score.round(2),
            quality_score: quality_score.round(2)
          }
        }
      end

      private

      def calculate_time_score(execution_time, context_data)
        # Normalize against best/worst times in the result set
        best_time = context_data[:best_time] || 0.001
        worst_time = context_data[:worst_time] || 10.0

        # Inverse scoring: faster = higher score
        return 100 if execution_time <= best_time
        return 0 if execution_time >= worst_time

        100 - (((execution_time - best_time) / (worst_time - best_time)) * 100)
      end

      def calculate_quality_score(rubocop_offenses)
        # Quality score: fewer offenses = higher score
        max_offenses = 50.0
        return 100 if rubocop_offenses <= 0
        return 0 if rubocop_offenses >= max_offenses

        100 - ((rubocop_offenses / max_offenses) * 100)
      end
    end
  end
end
