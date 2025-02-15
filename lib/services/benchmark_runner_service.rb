require_relative '../../config'
require_relative 'results_display_service'
require_relative 'results_service'
require_relative 'format_name_service'
require 'json'
require 'rubocop'

class BenchmarkRunnerService
  extend FormatNameService
  include FormatNameService

  NUM_ITERATIONS = 5

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
    puts "\nRunning benchmark with implementation: #{implementation[:name]}"
    puts "Running #{NUM_ITERATIONS} iterations in separate processes..."

    results = []
    NUM_ITERATIONS.times do |i|
      print "Iteration #{i + 1}/#{NUM_ITERATIONS}: "
      results << run_in_subprocess(implementation)
    end

    best_result = results.min
    rubocop_offenses_count = RubocopEvaluationService.count_offenses(implementation[:file])

    save_and_display_results(implementation, best_result, rubocop_offenses_count)
  end

  def run_in_subprocess(implementation)
    read, write = IO.pipe
    pid = fork do
      read.close
      result = run_single_benchmark(implementation)
      write.write(result.to_json)
      write.close
      exit!(0)
    end

    write.close
    result = JSON.parse(read.read).to_f
    read.close
    Process.wait(pid)

    puts "Execution time: #{result} seconds"
    result
  end

  def run_single_benchmark(implementation)
    benchmark_file = Config.benchmark_file(@benchmark_id)
    require_relative File.join('../..', benchmark_file)
    implementation_path = File.join('..', '..', implementation[:file])

    benchmark_class = Object.const_get("#{format_name(@benchmark_id).delete(' ')}Benchmark")
    benchmark_class.run(implementation_path)
  end

  def save_and_display_results(implementation, result, rubocop_offenses_count)
    results_service = ResultsService.new(Config.results_file(@benchmark_id))
    results_service.add_result(
      implementation[:name],
      result,
      rubocop_offenses_count
    )

    ResultsDisplayService.display(@benchmark_id)
  end
end
