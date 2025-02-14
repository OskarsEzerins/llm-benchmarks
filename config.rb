module Config
  module_function

  def benchmarks
    ['lru_cache']
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
