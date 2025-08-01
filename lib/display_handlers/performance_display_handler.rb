# frozen_string_literal: true

require_relative 'base_display_handler'

module DisplayHandlers
  class PerformanceDisplayHandler < BaseDisplayHandler
    def table_headings
      ['Rank', 'Implementation', 'Score (%)', 'Best Time (s)', 'Avg Time (s)', 'RuboCop', 'Runs', 'Date']
    end

    def create_ranking_row(result, index)
      implementation = result['implementation']
      aggregates = @aggregates[implementation]
      score = aggregates ? "#{aggregates['score']}%" : 'N/A'

      avg_time = aggregates ? aggregates['metrics']['execution_time'].round(4) : 'N/A'

      [
        index + 1,
        implementation,
        score,
        result['metrics']['execution_time'].round(4),
        avg_time,
        aggregates ? aggregates['rubocop_offenses'] : 'N/A',
        aggregates ? aggregates['run_count'] : 'N/A',
        format_time(result['timestamp'])
      ]
    end

    def display_summary
      return unless @best_results.any?

      puts "\n⚡ Performance Summary:"
      puts "  Best implementations optimized for speed and code quality"
    end
  end
end
