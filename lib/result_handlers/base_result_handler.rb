# frozen_string_literal: true

module ResultHandlers
  class BaseResultHandler
    def initialize(benchmark_id)
      @benchmark_id = benchmark_id
    end

    def calculate_implementation_metrics(impl_results)
      raise NotImplementedError, "Subclasses must implement calculate_implementation_metrics"
    end

    def calculate_best_results_by_implementation(results)
      raise NotImplementedError, "Subclasses must implement calculate_best_results_by_implementation"
    end

    protected

    def calculate_average_metrics(impl_results)
      return {} if impl_results.empty?

      metrics = impl_results.first['metrics']&.keys || []

      metrics.each_with_object({}) do |metric, acc|
        values = impl_results.filter_map { |r| r['metrics'][metric] }
        if values.any?
          # Handle boolean values
          if values.first.is_a?(TrueClass) || values.first.is_a?(FalseClass)
            acc[metric] = values.count(true).to_f / values.size
          else
            # Handle numeric values
            numeric_values = values.select { |v| v.is_a?(Numeric) }
            acc[metric] = numeric_values.any? ? (numeric_values.sum / numeric_values.size.to_f).round(6) : nil
          end
        else
          acc[metric] = nil
        end
      end
    end
  end
end
