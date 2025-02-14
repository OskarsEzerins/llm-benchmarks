#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require
require 'terminal-table'
require_relative 'lib/services/results_display_service'
require_relative 'lib/services/results_service'
require_relative 'lib/services/implementation_selector_service'

class BenchmarkRunner
  BENCHMARKS = ['lru_cache']

  def initialize
    @prompt = TTY::Prompt.new
  end

  def run
    benchmark = select_benchmark
    return puts "No benchmark selected." unless benchmark

    implementations = select_implementations(benchmark)
    run_benchmarks(benchmark, implementations)
  end

  private

  def select_benchmark
    @prompt.select(
      "\nSelect benchmark:",
      BENCHMARKS.map { |id| { name: format_name(id), value: id } },
      per_page: 20,
      filter: true,
      show_help: :always,
      cycle: true,
      filter_hint: '(Start typing to filter)'
    )
  end

  def select_implementations(benchmark_id)
    selector = ImplementationSelectorService.new(implementations_dir(benchmark_id))
    implementations = selector.select
    implementations.is_a?(Array) ? implementations : [implementations]
  end

  def run_benchmarks(benchmark_id, implementations)
    implementations.each do |implementation|
      run_single_benchmark(benchmark_id, implementation)
    end
  end

  def run_single_benchmark(benchmark_id, implementation)
    puts "\nRunning benchmark with implementation: #{implementation[:name]}"

    require_relative benchmark_file(benchmark_id)
    implementation_path = File.join('..', '..', implementation[:file])

    benchmark_class = Object.const_get("#{format_name(benchmark_id).gsub(' ', '')}Benchmark")
    result = benchmark_class.run(implementation_path)

    save_and_display_results(benchmark_id, implementation, result)
  end

  def save_and_display_results(benchmark_id, implementation, result)
    results_service = ResultsService.new(results_file(benchmark_id))
    results = results_service.add_result(
      implementation[:name],
      result[:execution_time],
      result[:parameters]
    )

    ResultsDisplayService.display(results, implementation[:name])
  end

  def format_name(benchmark_id)
    benchmark_id.split('_').map(&:capitalize).join(' ')
  end

  def implementations_dir(benchmark_id)
    "implementations/#{benchmark_id}"
  end

  def results_file(benchmark_id)
    "results/#{benchmark_id}.json"
  end

  def benchmark_file(benchmark_id)
    "benchmarks/#{benchmark_id}/benchmark"
  end
end

BenchmarkRunner.new.run
