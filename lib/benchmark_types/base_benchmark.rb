# frozen_string_literal: true

module BenchmarkTypes
  class BaseBenchmark
    class << self
      def benchmark_type
        raise NotImplementedError, "Subclasses must implement #benchmark_type"
      end

      def run(implementation_path)
        raise NotImplementedError, "Subclasses must implement #run"
      end

      def evaluate_result(raw_result)
        raise NotImplementedError, "Subclasses must implement #evaluate_result"
      end

      def supports_broken_code_handling?
        false
      end

      def required_methods
        %w[run evaluate_result benchmark_type]
      end

      def metric_names
        %w[primary_metric success]
      end

      def scoring_weight_config
        {}
      end
    end
  end
end
