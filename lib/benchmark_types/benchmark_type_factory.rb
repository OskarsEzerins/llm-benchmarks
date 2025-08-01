# frozen_string_literal: true

require_relative 'performance_benchmark'
require_relative 'program_fixer_benchmark'

module BenchmarkTypes
  class BenchmarkTypeFactory
    BENCHMARK_TYPES = {
      performance: PerformanceBenchmark,
      program_fixer: ProgramFixerBenchmark
    }.freeze

    class << self
      def create_benchmark(benchmark_id)
        benchmark_config = Config.benchmark_config(benchmark_id)
        benchmark_type = benchmark_config[:type] || :performance

        klass = BENCHMARK_TYPES[benchmark_type]
        raise ArgumentError, "Unknown benchmark type: #{benchmark_type}" unless klass

        klass
      end

      def benchmark_type_for(benchmark_id)
        create_benchmark(benchmark_id).benchmark_type
      end

      def available_types
        BENCHMARK_TYPES.keys
      end

      def supports_broken_code_handling?(benchmark_id)
        create_benchmark(benchmark_id).supports_broken_code_handling?
      end

      def metric_names_for(benchmark_id)
        create_benchmark(benchmark_id).metric_names
      end

      def scoring_weights_for(benchmark_id)
        create_benchmark(benchmark_id).scoring_weight_config
      end
    end
  end
end
