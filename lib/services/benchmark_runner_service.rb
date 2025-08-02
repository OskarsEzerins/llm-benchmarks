require_relative '../../config'
require_relative 'results_display_service'
require_relative 'results_service'
require_relative 'format_name_service'
require_relative 'rubocop_evaluation_service'
require_relative '../benchmark_types/benchmark_type_factory'
require 'json'
require 'rubocop'

class BenchmarkRunnerService
  extend FormatNameService
  include FormatNameService

  # Type-specific iteration configuration
  ITERATION_CONFIG = {
    performance: 5,        # Multiple iterations for statistical accuracy
    program_fixer: 1       # Single iteration for deterministic tests
  }.freeze

  def self.run_all
    Config.benchmarks.each do |benchmark_id|
      puts "\nRunning #{format_name(benchmark_id)}..."
      selector = ImplementationSelectorService.new(Config.implementations_dir(benchmark_id))
      implementations = selector.list_all
      new(benchmark_id, implementations).run
    end
  end

  def initialize(benchmark_id, implementations)
    @benchmark_id = benchmark_id
    @implementations = implementations
  end

  def run
    puts "\nRunning benchmarks in random order..."
    @implementations.shuffle.each do |implementation|
      run_implementation_iterations(implementation)
    end
  end

  private

  def run_implementation_iterations(implementation)
    benchmark_type = BenchmarkTypes::BenchmarkTypeFactory.benchmark_type_for(@benchmark_id)
    num_iterations = ITERATION_CONFIG[benchmark_type] || 1

    puts "\nRunning benchmark with implementation: #{implementation[:name]}"
    puts "Running #{num_iterations} iteration#{'s' if num_iterations > 1} (#{benchmark_type} type)..."

    results = []
    num_iterations.times do |i|
      print "Iteration #{i + 1}/#{num_iterations}: "
      results << run_in_subprocess(implementation)
    end

    best_result = select_best_result(results)
    rubocop_offenses_count = RubocopEvaluationService.count_offenses(implementation[:file])

    save_and_display_results(implementation, best_result, rubocop_offenses_count)
  end

  def run_in_subprocess(implementation)
    read, write = IO.pipe
    pid = fork do
      read.close

      # Preserve bundler environment in subprocess
      require 'bundler/setup'
      Bundler.require

      result = run_single_benchmark(implementation)
      write.write(result.to_json)
      write.close
      exit!(0)
    end

    write.close
    result_data = JSON.parse(read.read, symbolize_names: true)
    read.close
    Process.wait(pid)

    execution_time = result_data[:execution_time] || result_data[:primary_metric] || 0
    puts "Execution time: #{execution_time} seconds"
    result_data
  end

  def run_single_benchmark(implementation)
    benchmark_file = Config.benchmark_file(@benchmark_id)
    require_relative File.join('../..', benchmark_file)
    implementation_path = File.join('..', '..', implementation[:file])

    benchmark_type_class = BenchmarkTypes::BenchmarkTypeFactory.create_benchmark(@benchmark_id)
    benchmark_config = Config.benchmark_config(@benchmark_id)
    concrete_benchmark_class = Object.const_get(benchmark_config[:class_name])

    raw_result = concrete_benchmark_class.run(implementation_path)

    # puts "Raw result: #{raw_result.inspect}"

    benchmark_type_class.evaluate_result(raw_result)
  end

  def select_best_result(results)
    benchmark_type = BenchmarkTypes::BenchmarkTypeFactory.benchmark_type_for(@benchmark_id)

    case benchmark_type
    when :performance
      select_best_performance_result(results)
    when :program_fixer
      select_best_program_fixer_result(results)
    else
      select_best_default_result(results)
    end
  end

  def select_best_performance_result(results)
    results.min_by { |result| result[:execution_time] || Float::INFINITY }
  end

  def select_best_program_fixer_result(results)
    results.max_by do |result|
      [result[:success_rate] || 0, -(result[:execution_time] || Float::INFINITY)]
    end
  end

  def select_best_default_result(results)
    results.max_by { |result| result[:primary_metric] || 0 }
  end

  def save_and_display_results(implementation, result, rubocop_offenses_count)
    results_service = ResultsService.new(Config.results_file(@benchmark_id), @benchmark_id)
    results_service.add_result(
      implementation[:name],
      result,
      rubocop_offenses_count
    )

    ResultsDisplayService.display(@benchmark_id)
  end
end
