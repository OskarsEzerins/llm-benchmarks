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
    @performance_scores = {}
    @program_fixer_scores = {}
    load_all_results
    calculate_scores_by_type
  end

  def display
    display_rankings_by_type
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

  def calculate_scores_by_type
    @performance_scores = calculate_scores_for_type(:performance)
    @program_fixer_scores = calculate_scores_for_type(:program_fixer)
  end

  def calculate_scores_for_type(type)
    type_benchmarks = Config.benchmarks_by_type(type)

    # Only include implementations that have results for this benchmark type
    implementations_for_type = @benchmark_results
                               .slice(*type_benchmarks)
                               .values
                               .flat_map(&:keys)
                               .uniq

    implementations_for_type.to_h do |impl|
      [impl, calculate_implementation_score_for_type(impl, type)]
    end
  end

  def calculate_implementation_score_for_type(impl, type)
    type_benchmarks = Config.benchmarks_by_type(type)
    scores = type_benchmarks.map { |id| @benchmark_results[id]&.dig(impl, 'score') || 0 }

    return { score: 0, completed_benchmarks: 0, benchmark_scores: [] } if type_benchmarks.empty?

    {
      score: scores.sum / type_benchmarks.size.to_f,
      completed_benchmarks: scores.count(&:positive?),
      benchmark_scores: scores
    }
  end

  def display_rankings_by_type
    display_performance_rankings
    display_program_fixer_rankings
  end

  def display_performance_rankings
    performance_benchmarks = Config.benchmarks_by_type(:performance)
    return if performance_benchmarks.empty?

    table = Terminal::Table.new do |t|
      t.title = "Performance Implementation Rankings"
      t.headings = table_headings_for_type(:performance)
      sorted_implementations_for_type(:performance).each_with_index do |impl, index|
        t.add_row(create_table_row_for_type(impl, index, :performance))
      end
    end
    puts "\n#{table}"
  end

  def display_program_fixer_rankings
    program_fixer_benchmarks = Config.benchmarks_by_type(:program_fixer)
    return if program_fixer_benchmarks.empty?

    table = Terminal::Table.new do |t|
      t.title = "Program Fixer Implementation Rankings"
      t.headings = table_headings_for_type(:program_fixer)
      sorted_implementations_for_type(:program_fixer).each_with_index do |impl, index|
        t.add_row(create_table_row_for_type(impl, index, :program_fixer))
      end
    end
    puts "\n#{table}"
  end

  def table_headings_for_type(type)
    type_benchmarks = Config.benchmarks_by_type(type)
    ['Rank', 'Implementation', 'Total Score', 'Completed', *type_benchmarks.map { |b| format_benchmark_name(b) }]
  end

  def format_benchmark_name(benchmark)
    benchmark.split('_').map(&:capitalize).join(' ')
  end

  def create_table_row_for_type(impl, index, type)
    scores = type == :performance ? @performance_scores[impl] : @program_fixer_scores[impl]
    type_benchmarks = Config.benchmarks_by_type(type)

    [
      index + 1,
      impl,
      scores[:score].round(2),
      "#{scores[:completed_benchmarks]}/#{type_benchmarks.size}",
      *scores[:benchmark_scores].map { |s| s.round(2) }
    ]
  end

  def sorted_implementations_for_type(type)
    scores_hash = type == :performance ? @performance_scores : @program_fixer_scores
    scores_hash.keys.sort_by { |impl| -scores_hash[impl][:score] }
  end
end
