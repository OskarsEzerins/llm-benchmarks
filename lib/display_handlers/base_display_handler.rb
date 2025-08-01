# frozen_string_literal: true

require 'time'

module DisplayHandlers
  class BaseDisplayHandler
    def initialize(benchmark_id, best_results, aggregates)
      @benchmark_id = benchmark_id
      @best_results = best_results
      @aggregates = aggregates
    end

    def table_headings
      raise NotImplementedError, "Subclasses must implement table_headings"
    end

    def create_ranking_row(result, index)
      raise NotImplementedError, "Subclasses must implement create_ranking_row"
    end

    def display_summary
      # Optional: can be overridden by subclasses
    end

    def sorted_results
      @best_results.sort_by do |result|
        aggregates = @aggregates[result['implementation']]
        -(aggregates ? aggregates['score'] : -Float::INFINITY)
      end
    end

    protected

    def format_time(timestamp)
      Time.parse(timestamp).strftime('%Y-%m-%d %H:%M:%S')
    end

    def format_title
      formatted_name = @benchmark_id.split('_').map(&:capitalize).join(' ')
      "#{formatted_name} Implementation Benchmarks"
    end
  end
end
