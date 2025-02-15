require 'time'
require 'json'
require_relative '../helpers/results_helper'

class ResultsDisplayService
  include ResultsHelper

  def self.display(benchmark_id)
    new(benchmark_id).display
  end

  def initialize(benchmark_id)
    @benchmark_id = benchmark_id
    results_data = load_results
    @best_results = calculate_best_results_by_implementation(results_data['results'] || [])
    @aggregates = results_data['aggregates'] || {}
  end

  def display
    display_rankings_table
  end

  private

  def load_results
    results_file = "results/#{@benchmark_id}.json"
    File.exist?(results_file) ? JSON.parse(File.read(results_file)) : { 'results' => [], 'aggregates' => {} }
  rescue JSON::ParserError
    { 'results' => [], 'aggregates' => {} }
  end

  def display_rankings_table
    table = Terminal::Table.new do |t|
      t.title = format_title
      t.headings = ['Rank', 'Implementation', 'Score', 'Best Time (s)', 'Avg Time (s)', 'Rubocop', 'Runs', 'Date']
      sorted_results.each_with_index { |result, index| t.add_row(create_ranking_row(result, index)) }
    end

    puts "\n#{table}"
  end

  def create_ranking_row(result, index)
    implementation = result['implementation']
    aggregates = @aggregates[implementation]
    avg_time = aggregates ? aggregates['metrics']['execution_time'].round(4) : 'N/A'
    rubocop_offenses = aggregates ? aggregates['rubocop_offenses'] : 'N/A'
    score = aggregates ? aggregates['score'] : 'N/A'

    [
      index + 1,
      implementation,
      score,
      result['metrics']['execution_time'].round(4),
      avg_time,
      rubocop_offenses,
      aggregates ? aggregates['run_count'] : 'N/A',
      format_time(result['timestamp'])
    ]
  end

  def sorted_results
    @best_results.sort_by do |result|
      aggregates = @aggregates[result['implementation']]
      -(aggregates ? aggregates['score'] : -Float::INFINITY)
    end
  end

  def format_time(timestamp)
    Time.parse(timestamp).strftime('%Y-%m-%d %H:%M:%S')
  end

  def format_title
    formatted_name = @benchmark_id.split('_').map(&:capitalize).join(' ')
    "#{formatted_name} Implementation Benchmarks"
  end
end
