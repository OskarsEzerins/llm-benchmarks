# frozen_string_literal: true

require_relative 'performance_display_handler'
require_relative 'program_fixer_display_handler'
require_relative '../benchmark_types/benchmark_type_factory'

module DisplayHandlers
  class DisplayHandlerFactory
    class << self
      def create_handler(benchmark_id, best_results, aggregates)
        benchmark_type = BenchmarkTypes::BenchmarkTypeFactory.benchmark_type_for(benchmark_id)

        case benchmark_type
        when :program_fixer
          ProgramFixerDisplayHandler.new(benchmark_id, best_results, aggregates)
        when :performance
          PerformanceDisplayHandler.new(benchmark_id, best_results, aggregates)
        else
          raise ArgumentError, "Unknown benchmark type: #{benchmark_type}"
        end
      end
    end
  end
end
