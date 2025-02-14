#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require
require 'terminal-table'
require_relative 'config'
require_relative 'lib/services/results_display_service'
require_relative 'lib/services/results_service'
require_relative 'lib/services/implementation_selector_service'
require_relative 'lib/services/benchmark_runner_service'

class BenchmarkRunner
  def initialize
    @prompt = TTY::Prompt.new
  end

  def run
    benchmark = select_benchmark
    return puts 'No benchmark selected.' unless benchmark

    implementations = select_implementations(benchmark)
    BenchmarkRunnerService.new(benchmark, implementations).run
  end

  private

  def select_benchmark
    @prompt.select(
      "\nSelect benchmark:",
      Config.benchmarks.map { |id| { name: format_name(id), value: id } },
      per_page: 20,
      filter: true,
      show_help: :always,
      cycle: true,
      filter_hint: '(Start typing to filter)'
    )
  end

  def select_implementations(benchmark_id)
    selector = ImplementationSelectorService.new(Config.implementations_dir(benchmark_id))
    implementations = selector.select
    implementations.is_a?(Array) ? implementations : [implementations]
  end

  def format_name(benchmark_id)
    benchmark_id.split('_').map(&:capitalize).join(' ')
  end
end

BenchmarkRunner.new.run
