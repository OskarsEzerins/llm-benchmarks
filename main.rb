#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require
require 'terminal-table'
require 'pry'
require 'dotenv/load'
require_relative 'config'
require_relative 'lib/services/results_display_service'
require_relative 'lib/services/results_service'
require_relative 'lib/services/implementation_selector_service'
require_relative 'lib/services/rubocop_evaluation_service'
require_relative 'lib/services/benchmark_runner_service'
require_relative 'lib/services/format_name_service'
require_relative 'lib/services/single_model_benchmark_service'
require_relative 'lib/services/implementations/adder'

class Main
  include FormatNameService

  HIGH_LEVEL_OPTIONS = [
    { name: 'Run benchmarks', value: :run_benchmarks },
    { name: 'Add implementations', value: :add_implementations }
  ].freeze

  RUN_ALL_OPTION = { name: 'Run all benchmarks with all models', value: :all }.freeze
  RUN_SINGLE_MODEL_ALL_BENCHMARKS = { name: 'Run single model across all benchmarks', value: :single_model }.freeze

  def initialize
    @prompt = TTY::Prompt.new
  end

  def run
    choice = select_high_level_option

    case choice
    when :run_benchmarks
      run_benchmarks
    when :add_implementations
      Implementations::Adder.new.add
    end
  end

  private

  def select_high_level_option
    @prompt.select(
      "\nSelect operation:",
      HIGH_LEVEL_OPTIONS,
      filter: true,
      cycle: true
    )
  end

  def run_benchmarks
    benchmark = select_benchmark
    return puts 'No benchmark selected.' unless benchmark

    case benchmark
    when :all
      BenchmarkRunnerService.run_all
    when :single_model
      SingleModelBenchmarkService.new(@prompt).run
    else
      implementations = select_implementations(benchmark)
      BenchmarkRunnerService.new(benchmark, implementations).run
    end
  end

  def select_benchmark
    @prompt.select(
      "\nSelect benchmark:",
      [RUN_ALL_OPTION, RUN_SINGLE_MODEL_ALL_BENCHMARKS] + Config.benchmarks.map do |id|
        { name: format_name(id), value: id }
      end,
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
end

Main.new.run
