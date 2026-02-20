require 'json'
require 'fileutils'
require_relative '../result_handlers/result_handler_factory'
require_relative '../../config'

class ResultsService
  def initialize(benchmark_id)
    @benchmark_id = benchmark_id
    @result_handler = ResultHandlers::ResultHandlerFactory.create_handler(@benchmark_id)
  end

  # Returns { 'results' => [...all runs for this benchmark...], 'aggregates' => { impl => aggregate, ... } }
  def load
    results = []
    aggregates = {}

    Dir.glob("#{Config.results_dir}/*.json").each do |file|
      data = JSON.parse(File.read(file))
      benchmark_data = data[@benchmark_id]
      next unless benchmark_data

      implementation = data['implementation']
      next unless implementation

      results.concat(benchmark_data['results'] || [])
      aggregates[implementation] = benchmark_data['aggregate'] if benchmark_data['aggregate']
    rescue JSON::ParserError
      next
    end

    { 'results' => results, 'aggregates' => aggregates }
  end

  def add_result(implementation, result_data, rubocop_offenses)
    impl_file = Config.implementation_results_file(implementation)
    data = load_impl_file(impl_file, implementation)

    current_result = {
      'implementation' => implementation,
      'timestamp' => Time.now.iso8601,
      'metrics' => build_metrics(result_data, rubocop_offenses)
    }

    benchmark_data = data[@benchmark_id] ||= { 'results' => [] }

    benchmark_data['results'].clear if Config.benchmark_config(@benchmark_id)[:type] == :program_fixer

    benchmark_data['results'] << current_result
    benchmark_data['aggregate'] = @result_handler.calculate_implementation_metrics(benchmark_data['results'])

    FileUtils.mkdir_p(File.dirname(impl_file))
    File.write(impl_file, JSON.pretty_generate(data))

    { 'best_results' => [], 'aggregates' => { implementation => benchmark_data['aggregate'] } }
  end

  def calculate_best_results_by_implementation(results)
    @result_handler.calculate_best_results_by_implementation(results)
  end

  private

  def load_impl_file(file, implementation)
    return { 'implementation' => implementation } unless File.exist?(file)

    JSON.parse(File.read(file))
  rescue JSON::ParserError
    { 'implementation' => implementation }
  end

  def build_metrics(result_data, rubocop_offenses)
    base_metrics = { 'rubocop_offenses' => rubocop_offenses }

    if result_data.is_a?(Hash)
      result_data.each { |k, v| base_metrics[k.to_s] = v }
    else
      base_metrics['execution_time'] = result_data
      base_metrics['primary_metric'] = result_data
    end

    base_metrics
  end
end
