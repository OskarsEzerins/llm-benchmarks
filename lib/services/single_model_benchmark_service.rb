class SingleModelBenchmarkService
  include FormatNameService

  def initialize(prompt, benchmark_type = :all_types)
    @prompt = prompt
    @benchmark_type = benchmark_type
  end

  def run
    implementations = available_implementations
    implementation = select_from_available_implementations(implementations)
    return puts 'No implementation selected.' unless implementation

    target_benchmarks.each do |benchmark_id|
      run_benchmark_for_implementation(benchmark_id, implementation)
    end
  end

  private

  def target_benchmarks
    case @benchmark_type
    when :performance
      Config.benchmarks_by_type(:performance)
    when :program_fixer
      Config.benchmarks_by_type(:program_fixer)
    else # :all_types or any other value
      Config.benchmarks
    end
  end

  def available_implementations
    target_benchmarks.each_with_object(Set.new) do |benchmark_id, implementations|
      Dir.glob("#{Config.implementations_dir(benchmark_id)}/*.rb").each do |file|
        implementations << File.basename(file, '.rb')
      end
    end
  end

  def select_from_available_implementations(implementations)
    benchmark_type_text = case @benchmark_type
                          when :performance
                            'performance benchmarks'
                          when :program_fixer
                            'program fixer benchmarks'
                          else
                            'all benchmarks'
                          end

    selection = @prompt.select(
      "Choose an implementation to run across #{benchmark_type_text}:",
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
