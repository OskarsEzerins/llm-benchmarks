require 'json'
require 'fileutils'
require_relative '../helpers/results_helper'

class ResultsService
  include ResultsHelper

  def initialize(results_file)
    @results_file = results_file
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

  def add_result(implementation, execution_time, rubocop_offenses)
    data = load
    current_result = {
      'implementation' => implementation,
      'timestamp' => Time.now.iso8601,
      'metrics' => {
        'execution_time' => execution_time,
        'rubocop_offenses' => rubocop_offenses
      }
    }

    data['results'] << current_result
    data['aggregates'] = calculate_aggregates(data['results'])
    best_results = calculate_best_results_by_implementation(data['results'])

    save(data)
    { 'best_results' => best_results, 'aggregates' => data['aggregates'] }
  end

  private

  def calculate_best_results_by_implementation(results)
    results.group_by { |r| r['implementation'] }
           .map { |_, impl_results| impl_results.min_by { |r| r['metrics']['execution_time'] } }
           .sort_by { |r| r['metrics']['execution_time'] }
  end

  def calculate_aggregates(results)
    grouped = results.group_by { |r| r['implementation'] }
    metrics_bounds = calculate_metrics_bounds(results)

    grouped.transform_values do |impl_results|
      calculate_implementation_metrics(impl_results, metrics_bounds)
    end
  end

  def calculate_metrics_bounds(results)
    best_times = results.map { |r| r['metrics']['execution_time'] }
    {
      max_time: best_times.max,
      min_time: best_times.min,
      max_rubocop: results.filter_map { |r| r['metrics']['rubocop_offenses'] }.max || 0
    }
  end

  def calculate_implementation_metrics(impl_results, bounds)
    metrics = calculate_average_metrics(impl_results)
    best_time = impl_results.map { |r| r['metrics']['execution_time'] }.min
    rubocop_offenses = impl_results.filter_map { |r| r['metrics']['rubocop_offenses'] }.max || 0

    scores = calculate_scores(best_time, metrics['execution_time'], rubocop_offenses, bounds)

    {
      'run_count' => impl_results.size,
      'metrics' => metrics,
      'rubocop_offenses' => rubocop_offenses,
      'score' => scores.sum / 3.0
    }
  end

  def calculate_scores(best_time, avg_time, rubocop_offenses, bounds)
    [
      normalize_inverse_score(best_time, bounds[:min_time], bounds[:max_time]),
      normalize_inverse_score(avg_time, bounds[:min_time], bounds[:max_time]),
      normalize_inverse_score(rubocop_offenses, 0, bounds[:max_rubocop])
    ].map { |score| score.round(2) }
  end

  def normalize_inverse_score(value, min_val, max_val)
    return 100 if max_val == min_val

    range = max_val - min_val
    100 - (((value - min_val) / range) * 100)
  end

  def calculate_average_metrics(impl_results)
    metrics = impl_results.first['metrics'].keys
    metrics.each_with_object({}) do |metric, acc|
      values = impl_results.filter_map { |r| r['metrics'][metric] }
      acc[metric] = values.any? ? (values.sum / values.size.to_f).round(6) : nil
    end
  end
end
