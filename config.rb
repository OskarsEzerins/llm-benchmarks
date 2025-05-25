require_relative 'config/ruby_llm'

module Config
  module_function

  def benchmarks
    ['lru_cache', 'graph_shortest_paths', 'run_length_encoding', 'csv_processor']
  end

  def results_dir
    'results'
  end

  def implementations_dir(benchmark_id)
    "implementations/#{benchmark_id}"
  end

  def results_file(benchmark_id)
    "#{results_dir}/#{benchmark_id}.json"
  end

  def benchmark_file(benchmark_id)
    "benchmarks/#{benchmark_id}/benchmark"
  end
end
