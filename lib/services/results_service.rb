require 'json'
require 'fileutils'
require 'time'
require_relative '../result_handlers/result_handler_factory'
require_relative '../../config'
require_relative 'implementations/model_variant_registry'

class ResultsService
  def initialize(benchmark_id)
    @benchmark_id = benchmark_id
    @result_handler = ResultHandlers::ResultHandlerFactory.create_handler(@benchmark_id)
    @variant_registry = Implementations::ModelVariantRegistry.instance
  end

  # Returns benchmark results plus per-implementation aggregate, metadata, and generation timing maps.
  def load
    Dir.glob("#{Config.results_dir}/*.json").each_with_object(empty_results_payload) do |file, payload|
      merge_result_file(payload, file)
    end
  end

  def add_result(implementation, result_data, rubocop_offenses, metadata = nil)
    context = result_context(implementation, metadata)
    benchmark_data = benchmark_data_for(context.fetch(:data))
    replace_program_fixer_results(benchmark_data)
    benchmark_data['results'] << current_result(implementation, result_data, rubocop_offenses)
    benchmark_data['aggregate'] = @result_handler.calculate_implementation_metrics(benchmark_data['results'])

    write_impl_file(context.fetch(:file), context.fetch(:data))
    aggregate_response(implementation, benchmark_data)
  end

  def record_generation_timing(implementation, timing_data, metadata = nil)
    impl_file = Config.implementation_results_file(implementation)
    metadata ||= @variant_registry.find_by_implementation(implementation)
    data = load_impl_file(impl_file, implementation, metadata)
    data['implementation_metadata'] = metadata if metadata

    benchmark_data = data[@benchmark_id] ||= { 'results' => [] }
    benchmark_data['generation_timing'] = timing_data

    FileUtils.mkdir_p(File.dirname(impl_file))
    File.write(impl_file, JSON.pretty_generate(data))
  end

  def calculate_best_results_by_implementation(results)
    @result_handler.calculate_best_results_by_implementation(results)
  end

  private

  def empty_results_payload
    {
      'results' => [],
      'aggregates' => {},
      'implementations_meta' => {},
      'generation_timings' => {}
    }
  end

  def merge_result_file(payload, file)
    data = JSON.parse(File.read(file))
    benchmark_data = data[@benchmark_id]
    implementation = data['implementation']
    return unless benchmark_data && implementation

    metadata = data['implementation_metadata'] || @variant_registry.find_by_implementation(implementation)
    payload['results'].concat(benchmark_data['results'] || [])
    payload['aggregates'][implementation] = benchmark_data['aggregate'] if benchmark_data['aggregate']
    payload['implementations_meta'][implementation] = metadata if metadata
    add_generation_timing(payload, implementation, benchmark_data)
  rescue JSON::ParserError
    nil
  end

  def add_generation_timing(payload, implementation, benchmark_data)
    return unless benchmark_data['generation_timing']

    payload['generation_timings'][implementation] = benchmark_data['generation_timing']
  end

  def result_context(implementation, metadata)
    impl_file = Config.implementation_results_file(implementation)
    metadata ||= @variant_registry.find_by_implementation(implementation)
    data = load_impl_file(impl_file, implementation, metadata)
    data['implementation_metadata'] = metadata if metadata

    { file: impl_file, data: data }
  end

  def benchmark_data_for(data)
    data[@benchmark_id] ||= { 'results' => [] }
  end

  def replace_program_fixer_results(benchmark_data)
    benchmark_data['results'].clear if Config.benchmark_config(@benchmark_id)[:type] == :program_fixer
  end

  def current_result(implementation, result_data, rubocop_offenses)
    {
      'implementation' => implementation,
      'timestamp' => Time.now.iso8601,
      'metrics' => build_metrics(result_data, rubocop_offenses)
    }
  end

  def write_impl_file(file, data)
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, JSON.pretty_generate(data))
  end

  def aggregate_response(implementation, benchmark_data)
    { 'best_results' => [], 'aggregates' => { implementation => benchmark_data['aggregate'] } }
  end

  def load_impl_file(file, implementation, metadata = nil)
    return base_impl_payload(implementation, metadata) unless File.exist?(file)

    parsed = JSON.parse(File.read(file))
    parsed['implementation_metadata'] ||= metadata if metadata
    parsed
  rescue JSON::ParserError
    base_impl_payload(implementation, metadata)
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

  def base_impl_payload(implementation, metadata)
    payload = { 'implementation' => implementation }
    payload['implementation_metadata'] = metadata if metadata
    payload
  end
end
