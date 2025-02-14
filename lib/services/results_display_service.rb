require 'time'
require_relative '../helpers/results_helper'

class ResultsDisplayService
  include ResultsHelper

  def self.display(results, current_implementation, benchmark_id)
    new(results, current_implementation, benchmark_id).display
  end

  def initialize(results, current_implementation, benchmark_id)
    @best_results = results['best_results'] || calculate_best_results_by_implementation(results['results'] || [])
    @averages = results['averages']
    @current_implementation = current_implementation
    @benchmark_id = benchmark_id
  end

  def display
    display_rankings_table
    display_details_table if @current_implementation
  end

  private

  def display_rankings_table
    table = Terminal::Table.new do |t|
      t.title = format_title
      t.headings = ['Rank', 'Implementation', 'Best Time (s)', 'Avg Time (s)', 'Runs', 'Date', 'Status']
      sorted_results.each_with_index { |result, index| t.add_row(create_ranking_row(result, index)) }
    end

    puts "\n#{table}"
  end

  def create_ranking_row(result, index)
    implementation = result['implementation']
    status = implementation == @current_implementation ? '🆕' : ' '
    avg_metrics = @averages[implementation]
    avg_time = avg_metrics ? avg_metrics['metrics']['execution_time'].round(4) : 'N/A'

    [
      index + 1,
      implementation,
      result['metrics']['execution_time'],
      avg_time,
      avg_metrics ? avg_metrics['run_count'] : 'N/A',
      format_time(result['timestamp']),
      status
    ]
  end

  def sorted_results
    @best_results.sort_by do |result|
      avg_metrics = @averages[result['implementation']]
      avg_metrics ? avg_metrics['metrics']['execution_time'] : Float::INFINITY
    end
  end

  def display_details_table
    current_result = @best_results.find { |r| r['implementation'] == @current_implementation }
    return unless current_result

    puts "\nLatest Best Run Details:"
    details_table = Terminal::Table.new do |t|
      t.style = { width: 80 }
      t.add_row ['Implementation', @current_implementation]
      t.add_separator
      current_result['metrics'].each do |metric, value|
        t.add_row [metric.split('_').map(&:capitalize).join(' '), value]
      end
    end
    puts details_table
  end

  def format_time(timestamp)
    Time.parse(timestamp).strftime('%Y-%m-%d %H:%M:%S')
  end

  def format_title
    formatted_name = @benchmark_id.split('_').map(&:capitalize).join(' ')
    "#{formatted_name} Implementation Benchmarks"
  end
end
