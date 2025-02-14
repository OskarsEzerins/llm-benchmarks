require 'json'
require 'fileutils'
require_relative '../helpers/results_helper'

class ResultsService
  include ResultsHelper

  def initialize(results_file)
    @results_file = results_file
  end

  def load
    File.exist?(@results_file) ? JSON.parse(File.read(@results_file)) : { "results" => [], "averages" => {} }
  rescue JSON::ParserError
    { "results" => [], "averages" => {} }
  end

  def save(data)
    FileUtils.mkdir_p(File.dirname(@results_file))
    File.write(@results_file, JSON.pretty_generate(data))
  end

  def add_result(implementation, execution_time)
    data = load
    current_result = {
      "implementation" => implementation,
      "timestamp" => Time.now.iso8601,
      "metrics" => {
        "execution_time" => execution_time
      }
    }

    data["results"] << current_result
    data["averages"] = calculate_averages(data["results"])
    best_results = calculate_best_results_by_implementation(data["results"])

    save(data)
    { "best_results" => best_results, "averages" => data["averages"] }
  end

  private

  def calculate_best_results_by_implementation(results)
    results.group_by { |r| r["implementation"] }
           .map { |_, impl_results| impl_results.min_by { |r| r["metrics"]["execution_time"] } }
           .sort_by { |r| r["metrics"]["execution_time"] }
  end

  def calculate_averages(results)
    grouped = results.group_by { |r| r["implementation"] }
    grouped.transform_values do |impl_results|
      metrics = impl_results.first["metrics"].keys
      avg_metrics = metrics.each_with_object({}) do |metric, acc|
        values = impl_results.map { |r| r["metrics"][metric] }.compact
        acc[metric] = values.any? ? (values.sum / values.size.to_f).round(6) : nil
      end
      {
        "run_count" => impl_results.size,
        "metrics" => avg_metrics
      }
    end
  end
end
