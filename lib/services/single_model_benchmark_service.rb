class SingleModelBenchmarkService
  include FormatNameService

  def initialize(prompt)
    @prompt = prompt
  end

  def run
    implementations = available_implementations
    implementation = select_from_available_implementations(implementations)
    return puts 'No implementation selected.' unless implementation

    Config.benchmarks.each do |benchmark_id|
      run_benchmark_for_implementation(benchmark_id, implementation)
    end
  end

  private

  def available_implementations
    Config.benchmarks.each_with_object(Set.new) do |benchmark_id, implementations|
      Dir.glob("#{Config.implementations_dir(benchmark_id)}/*.rb").each do |file|
        implementations << File.basename(file, '.rb')
      end
    end
  end

  def select_from_available_implementations(implementations)
    selection = @prompt.select(
      'Choose an implementation to run across all benchmarks:',
      implementations.to_a,
      per_page: 20,
      filter: true,
      cycle: true,
      filter_hint: '(Start typing to filter)'
    )
    { name: selection }
  end

  def run_benchmark_for_implementation(benchmark_id, implementation)
    implementation_file = Config.implementations_dir(benchmark_id) + "/#{implementation[:name]}.rb"

    unless File.exist?(implementation_file)
      puts "\nSkipping #{format_name(benchmark_id)} - implementation '#{implementation[:name]}' not found"
      return
    end

    puts "\nRunning #{format_name(benchmark_id)}..."
    BenchmarkRunnerService.new(
      benchmark_id,
      [{ name: implementation[:name], file: implementation_file }]
    ).run
  end
end
