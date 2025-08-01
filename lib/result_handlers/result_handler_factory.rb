# frozen_string_literal: true

require_relative 'performance_result_handler'
require_relative 'program_fixer_result_handler'
require_relative '../benchmark_types/benchmark_type_factory'

module ResultHandlers
  class ResultHandlerFactory
    class << self
      def create_handler(benchmark_id)
        benchmark_type = BenchmarkTypes::BenchmarkTypeFactory.benchmark_type_for(benchmark_id)

        case benchmark_type
        when :program_fixer
          ProgramFixerResultHandler.new(benchmark_id)
        when :performance
          PerformanceResultHandler.new(benchmark_id)
        else
          raise ArgumentError, "Unknown benchmark type: #{benchmark_type}"
        end
      end
    end
  end
end
