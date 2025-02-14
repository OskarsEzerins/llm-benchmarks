require 'json'
require 'fileutils'

class ResultsService
  def initialize(results_file)
    @results_file = results_file
  end

  def load
    File.exist?(@results_file) ? JSON.parse(File.read(@results_file)) : []
  rescue JSON::ParserError
    []
  end

  def save(results)
    FileUtils.mkdir_p(File.dirname(@results_file))
    File.write(@results_file, JSON.pretty_generate(results))
  end

  def add_result(implementation, execution_time, parameters)
    results = load
    current_result = {
      "implementation" => implementation,
      "timestamp" => Time.now.iso8601,
      "metrics" => {
        "execution_time" => execution_time,
        **parameters
      }
    }

    results << current_result
    results = keep_fastest_results(results)
    results.sort_by! { |r| r["metrics"]["execution_time"] }

    save(results)
    results
  end

  private

  def keep_fastest_results(results)
    results.group_by { |r| r['implementation'] }
           .map { |_, impl_results| impl_results.min_by { |r| r['metrics']['execution_time'] } }
  end
end
