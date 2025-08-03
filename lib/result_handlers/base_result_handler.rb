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
        acc[metric] = values.any? ? calculate_metric_average(values) : nil
      end
    end

    private

    def calculate_metric_average(values)
      return calculate_boolean_average(values) if boolean_values?(values)

      calculate_numeric_average(values)
    end

    def boolean_values?(values)
      values.first.is_a?(TrueClass) || values.first.is_a?(FalseClass)
    end

    def calculate_boolean_average(values)
      values.count(true).to_f / values.size
    end

    def calculate_numeric_average(values)
      numeric_values = values.select { |v| v.is_a?(Numeric) }
      return nil unless numeric_values.any?

      (numeric_values.sum / numeric_values.size.to_f).round(6)
    end
  end
end
