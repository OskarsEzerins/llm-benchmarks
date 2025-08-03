# frozen_string_literal: true

require_relative 'base_display_handler'

module DisplayHandlers
  class ProgramFixerDisplayHandler < BaseDisplayHandler
    def table_headings
      ['Rank', 'Implementation', 'Score (%)', 'Tests Passed', 'Success Rate (%)', 'RuboCop', 'Runs', 'Date']
    end

    def create_ranking_row(result, index)
      implementation = result['implementation']
      aggregates = @aggregates[implementation]
      score = aggregates ? "#{aggregates['score']}%" : 'N/A'

      success_rate = result['metrics']['success_rate']
      success_rate_pct = success_rate ? "#{(success_rate * 100).round(1)}%" : 'N/A'

      [
        index + 1,
        implementation,
        score,
        "#{result['metrics']['tests_passed']}/#{result['metrics']['total_tests']}",
        success_rate_pct,
        aggregates ? aggregates['rubocop_offenses'] : 'N/A',
        aggregates ? aggregates['run_count'] : 'N/A',
        format_time(result['timestamp'])
      ]
    end

    def display_summary
      return unless @best_results.any?

      puts "\n📊 Program Fixer Summary:"
      @best_results.each do |result|
        impl = result['implementation']
        agg = @aggregates[impl]
        next unless agg && agg['score_breakdown']

        breakdown = agg['score_breakdown']
        puts "  #{impl}: #{breakdown['success_score']}% tests + " \
             "#{breakdown['quality_score']}% quality = #{agg['score']}%"
      end
    end
  end
end
