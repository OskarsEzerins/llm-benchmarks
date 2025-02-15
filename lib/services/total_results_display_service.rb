require 'terminal-table'
require_relative '../../config'
require_relative '../helpers/results_helper'

class TotalResultsDisplayService
  include ResultsHelper

  def self.display
    new.display
  end

  def initialize
    @benchmark_results = {}
    @total_scores = {}
    load_all_results
    calculate_total_scores
  end

  def display
    display_total_rankings_table
  end

  private

  def load_all_results
    Config.benchmarks.each do |benchmark_id|
      results_file = Config.results_file(benchmark_id)
      next unless File.exist?(results_file)

      data = JSON.parse(File.read(results_file))
      @benchmark_results[benchmark_id] = data['aggregates']
    end
  end

  def calculate_total_scores
    all_implementations = @benchmark_results.values.flat_map(&:keys).uniq
    @total_scores = all_implementations.to_h { |impl| [impl, calculate_implementation_total_score(impl)] }
  end

  def calculate_implementation_total_score(impl)
    scores = collect_benchmark_scores(impl)
    {
      score: scores.sum / Config.benchmarks.size.to_f,
      completed_benchmarks: scores.count(&:positive?),
      benchmark_scores: scores
    }
  end

  def collect_benchmark_scores(impl)
    Config.benchmarks.map { |id| @benchmark_results[id]&.dig(impl, 'score') || 0 }
  end

  def display_total_rankings_table
    table = Terminal::Table.new do |t|
      t.title = "Total Implementation Rankings Across All Benchmarks"
      t.headings = table_headings
      sorted_implementations.each_with_index { |impl, index| t.add_row(create_table_row(impl, index)) }
    end
    puts "\n#{table}"
  end

  def table_headings
    ['Rank', 'Implementation', 'Total Score', 'Completed', *Config.benchmarks.map { |b| format_benchmark_name(b) }]
  end

  def format_benchmark_name(benchmark)
    benchmark.split('_').map(&:capitalize).join(' ')
  end

  def create_table_row(impl, index)
    scores = @total_scores[impl]
    [
      index + 1,
      impl,
      scores[:score].round(2),
      "#{scores[:completed_benchmarks]}/#{Config.benchmarks.size}",
      *scores[:benchmark_scores].map { |s| s.round(2) }
    ]
  end

  def sorted_implementations
    @total_scores.keys.sort_by { |impl| -@total_scores[impl][:score] }
  end
end
