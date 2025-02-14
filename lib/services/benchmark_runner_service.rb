require_relative '../../config'
require_relative 'results_display_service'
require_relative 'results_service'

class BenchmarkRunnerService
  NUM_ITERATIONS = 5

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
    save_and_display_results(implementation, best_result)
  end

  def run_in_subprocess(implementation)
    read, write = IO.pipe
    pid = fork do
      read.close
      result = run_single_benchmark(implementation)
      write.write(Marshal.dump(result))
      write.close
      exit!(0)
    end

    write.close
    result = Marshal.load(read.read)
    read.close
    Process.wait(pid)

    puts "Execution time: #{result} seconds"
    result
  end

  def run_single_benchmark(implementation)
    benchmark_file = Config.benchmark_file(@benchmark_id)
    require_relative File.join('../..', benchmark_file)
    implementation_path = File.join('..', '..', implementation[:file])

    benchmark_class = Object.const_get("#{format_name(@benchmark_id).gsub(' ', '')}Benchmark")
    benchmark_class.run(implementation_path)
  end

  def save_and_display_results(implementation, result)
    results_service = ResultsService.new(Config.results_file(@benchmark_id))
    results = results_service.add_result(
      implementation[:name],
      result
    )

    ResultsDisplayService.display(results, implementation[:name])
  end

  def format_name(benchmark_id)
    benchmark_id.split('_').map(&:capitalize).join(' ')
  end
end
