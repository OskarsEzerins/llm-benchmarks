# frozen_string_literal: true

require_relative 'base_result_handler'
require_relative '../benchmark_types/benchmark_type_factory'

module ResultHandlers
  class ProgramFixerResultHandler < BaseResultHandler
    def calculate_implementation_metrics(impl_results)
      metrics = calculate_average_metrics(impl_results)
      rubocop_offenses = impl_results.filter_map { |r| r['metrics']['rubocop_offenses'] }.max || 0

      # Get the best result for this implementation
      best_result = select_best_result(impl_results)
      best_result_metrics = best_result ? best_result['metrics'] : {}

      # Use the benchmark class to calculate percentage score
      benchmark_class = BenchmarkTypes::BenchmarkTypeFactory.create_benchmark(@benchmark_id)

      # Convert string keys to symbol keys
      result_data = {
        success_rate: best_result_metrics['success_rate'] || 0,
        execution_time: best_result_metrics['execution_time'] || 0,
        tests_passed: best_result_metrics['tests_passed'] || 0,
        total_tests: best_result_metrics['total_tests'] || 0
      }

      # Calculate score using the benchmark class method
      score_data = benchmark_class.calculate_percentage_score(
        result_data,
        rubocop_offenses,
        {}
      )

      {
        'run_count' => impl_results.size,
        'metrics' => metrics,
        'rubocop_offenses' => rubocop_offenses,
        'score' => score_data[:score],
        'score_breakdown' => score_data[:breakdown]
      }
    end

    def calculate_best_results_by_implementation(results)
      results.group_by { |r| r['implementation'] }
             .map { |_, impl_results| select_best_result(impl_results) }
             .compact
             .sort_by { |r| -(r['metrics']['success_rate'] || 0) }
    end

    private

    def select_best_result(impl_results)
      impl_results.max_by { |r| r['metrics']['success_rate'] || 0 }
    end
  end
end
