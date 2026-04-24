require_relative 'config/ruby_llm'

module Config
  module_function

  def root_path
    Dir.pwd
  end

  def benchmarks
    benchmark_configs.keys
  end

  def benchmark_configs
    {
      'lru_cache' => { type: :performance, class_name: 'LruCacheBenchmark' },
      'graph_shortest_paths' => { type: :performance, class_name: 'GraphShortestPathsBenchmark' },
      'run_length_encoding' => { type: :performance, class_name: 'RunLengthEncodingBenchmark' },
      'csv_processor' => { type: :performance, class_name: 'CsvProcessorBenchmark' },
      'vending_machine' => { type: :program_fixer, class_name: 'VendingMachineBenchmark' },
      'calendar' => { type: :program_fixer, class_name: 'CalendarBenchmark' },
      'parking_garage' => { type: :program_fixer, class_name: 'ParkingGarageBenchmark' },
      'school_library' => { type: :program_fixer, class_name: 'SchoolLibraryBenchmark' }
    }
  end

  def benchmark_config(benchmark_id)
    benchmark_configs[benchmark_id] || { type: :performance,
                                         class_name: "#{format_benchmark_name(benchmark_id)}Benchmark" }
  end

  def benchmarks_by_type(type)
    benchmark_configs.select { |_, config| config[:type] == type }.keys
  end

  def results_dir
    'results'
  end

  def implementations_dir(benchmark_id)
    benchmark_type = benchmark_configs[benchmark_id]&.dig(:type) || :performance
    "implementations/#{benchmark_type}/#{benchmark_id}"
  end

  def implementation_results_file(implementation_name)
    "#{results_dir}/#{implementation_name}.json"
  end

  def benchmark_file(benchmark_id)
    benchmark_type = benchmark_configs[benchmark_id]&.dig(:type) || :performance
    "benchmarks/#{benchmark_type}/#{benchmark_id}/benchmark"
  end

  def benchmark_prompt(benchmark_id)
    benchmark_type = benchmark_configs[benchmark_id]&.dig(:type) || :performance
    "benchmarks/#{benchmark_type}/#{benchmark_id}/prompt"
  end

  private

  def format_benchmark_name(benchmark_id)
    benchmark_id.split('_').map(&:capitalize).join
  end
end
