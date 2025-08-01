# frozen_string_literal: true

require_relative 'base_benchmark'

module BenchmarkTypes
  class ProgramFixerBenchmark < BaseBenchmark
    class << self
      def benchmark_type
        :program_fixer
      end

      def supports_broken_code_handling?
        true
      end

      def evaluate_result(raw_result)
        return failure_result unless raw_result.is_a?(Hash)

        tests_passed = raw_result[:tests_passed] || 0
        total_tests = raw_result[:total_tests] || 1
        success_rate = total_tests.positive? ? tests_passed.to_f / total_tests : 0

        {
          tests_passed: tests_passed,
          total_tests: total_tests,
          success_rate: success_rate,
          primary_metric: success_rate,
          success: raw_result[:success] == true,
          execution_time: raw_result[:execution_time] || 0
        }
      end

      def metric_names
        %w[tests_passed total_tests success_rate primary_metric success execution_time]
      end

      def scoring_weight_config
        {
          success_rate_weight: 0.7,
          quality_weight: 0.2,
          time_weight: 0.1
        }
      end

      def calculate_percentage_score(result_data, rubocop_offenses, _context_data)
        success_score = (result_data[:success_rate] * 100).round(2)
        quality_score = calculate_quality_score(rubocop_offenses)
        time_bonus = calculate_time_bonus(result_data[:execution_time])

        weights = scoring_weight_config
        final_score = (success_score * weights[:success_rate_weight]) +
                      (quality_score * weights[:quality_weight]) +
                      (time_bonus * weights[:time_weight])

        # Cap at 100%
        capped_score = [final_score, 100].min.round(2)

        {
          score: capped_score,
          breakdown: {
            success_score: success_score,
            quality_score: quality_score.round(2),
            time_bonus: time_bonus.round(2)
          }
        }
      end

      private

      def calculate_quality_score(rubocop_offenses)
        # Quality score: fewer offenses = higher score
        max_offenses = 50.0
        return 100 if rubocop_offenses <= 0
        return 0 if rubocop_offenses >= max_offenses

        100 - ((rubocop_offenses / max_offenses) * 100)
      end

      def calculate_time_bonus(execution_time)
        # Fast execution gives bonus points (0-100 scale)
        return 100 if execution_time <= 0.001
        return 0 if execution_time >= 1.0

        100 * (1 - execution_time).clamp(0, 1)
      end

      def failure_result
        {
          tests_passed: 0,
          total_tests: 0,
          success_rate: 0,
          primary_metric: 0,
          success: false,
          execution_time: 0
        }
      end
    end
  end
end
