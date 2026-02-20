require 'time'
require 'json'
require 'terminal-table'
require_relative '../helpers/results_helper'
require_relative '../display_handlers/display_handler_factory'
require_relative 'results_service'

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
    @display_handler = DisplayHandlers::DisplayHandlerFactory.create_handler(
      @benchmark_id,
      @best_results,
      @aggregates
    )
  end

  def display
    display_rankings_table
  end

  private

  def load_results
    ResultsService.new(@benchmark_id).load
  end

  def calculate_best_results_by_implementation(results)
    ResultsService.new(@benchmark_id).calculate_best_results_by_implementation(results)
  end

  def display_rankings_table
    table = Terminal::Table.new do |t|
      t.title = format_title
      t.headings = @display_handler.table_headings
      @display_handler.sorted_results.each_with_index do |result, index|
        t.add_row(@display_handler.create_ranking_row(result, index))
      end
    end

    puts "\n#{table}"
    @display_handler.display_summary if @best_results.any?
  end

  def format_title
    formatted_name = @benchmark_id.split('_').map(&:capitalize).join(' ')
    "#{formatted_name} Implementation Benchmarks"
  end
end
