require 'json'
require 'fileutils'
require_relative '../helpers/results_helper'
require_relative '../result_handlers/result_handler_factory'
require_relative '../../config'

class ResultsService
  include ResultsHelper

  def initialize(results_file, benchmark_id = nil)
    @results_file = results_file
    @benchmark_id = benchmark_id || extract_benchmark_id_from_file(results_file)
    @result_handler = ResultHandlers::ResultHandlerFactory.create_handler(@benchmark_id)
  end

  def load
    File.exist?(@results_file) ? JSON.parse(File.read(@results_file)) : { 'results' => [], 'aggregates' => {} }
  rescue JSON::ParserError
    { 'results' => [], 'aggregates' => {} }
  end

  def save(data)
    FileUtils.mkdir_p(File.dirname(@results_file))
    File.write(@results_file, JSON.pretty_generate(data))
  end

  def add_result(implementation, result_data, rubocop_offenses)
    data = load

    current_result = {
      'implementation' => implementation,
      'timestamp' => Time.now.iso8601,
      'metrics' => build_metrics(result_data, rubocop_offenses)
    }

    # For program_fixer benchmarks, replace any existing result for this implementation
    # For performance benchmarks, keep all results for iteration history
    benchmark_config = Config.benchmark_config(@benchmark_id)
    if benchmark_config[:type] == :program_fixer
      # Remove any existing results for this implementation
      data['results'].reject! { |r| r['implementation'] == implementation }
    end

    data['results'] << current_result
    data['aggregates'] = calculate_aggregates(data['results'])
    best_results = @result_handler.calculate_best_results_by_implementation(data['results'])

    save(data)
    { 'best_results' => best_results, 'aggregates' => data['aggregates'] }
  end

  def calculate_best_results_by_implementation(results)
    @result_handler.calculate_best_results_by_implementation(results)
  end

  private

  def extract_benchmark_id_from_file(results_file)
    File.basename(results_file, '.json')
  end

  def build_metrics(result_data, rubocop_offenses)
    base_metrics = { 'rubocop_offenses' => rubocop_offenses }

    if result_data.is_a?(Hash)
      result_data.each { |k, v| base_metrics[k.to_s] = v }
    else
      # Legacy support for simple numeric results
      base_metrics['execution_time'] = result_data
      base_metrics['primary_metric'] = result_data
    end

    base_metrics
  end

  def calculate_aggregates(results)
    grouped = results.group_by { |r| r['implementation'] }

    grouped.transform_values do |impl_results|
      @result_handler.calculate_implementation_metrics(impl_results)
    end
  end
end
