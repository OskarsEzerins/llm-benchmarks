#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require
require 'terminal-table'
require 'pry'
require 'dotenv/load'
require 'minitest'
require_relative 'config'
require_relative 'lib/services/results_display_service'
require_relative 'lib/services/results_service'
require_relative 'lib/services/implementation_selector_service'
require_relative 'lib/services/rubocop_evaluation_service'
require_relative 'lib/services/benchmark_runner_service'
require_relative 'lib/services/format_name_service'
require_relative 'lib/services/single_model_benchmark_service'
require_relative 'lib/services/benchmark_type_selector_service'
require_relative 'lib/services/implementations/adder'

class Main
  include FormatNameService

  HIGH_LEVEL_OPTIONS = [
    { name: 'Add implementations', value: :add_implementations },
    { name: 'Run benchmarks', value: :run_benchmarks }
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
      added = Implementations::Adder.new.add
      run_benchmarks_for_added(added) if added.any?
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
    benchmark_type = BenchmarkTypeSelectorService.new.select(:benchmark)
    return puts 'No benchmark type selected.' unless benchmark_type

    benchmark = select_benchmark(benchmark_type)
    return puts 'No benchmark selected.' unless benchmark

    case benchmark
    when :all
      if benchmark_type == :all_types
        BenchmarkRunnerService.run_all
      else
        run_all_benchmarks_of_type(benchmark_type)
      end
    when :single_model
      SingleModelBenchmarkService.new(@prompt, benchmark_type).run
    else
      implementations = select_implementations(benchmark)
      BenchmarkRunnerService.new(benchmark, implementations).run
    end
  end

  def select_benchmark(benchmark_type)
    available_benchmarks = get_benchmarks_for_type(benchmark_type)

    @prompt.select(
      "\nSelect benchmark:",
      [RUN_ALL_OPTION, RUN_SINGLE_MODEL_ALL_BENCHMARKS] + available_benchmarks.map do |id|
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
    selector = ImplementationSelectorService.new(Config.implementations_dir(benchmark_id)) # uses type-based path
    implementations = selector.select
    implementations.is_a?(Array) ? implementations : [implementations]
  end

  def get_benchmarks_for_type(benchmark_type)
    case benchmark_type
    when :performance
      Config.benchmarks_by_type(:performance)
    when :program_fixer
      Config.benchmarks_by_type(:program_fixer)
    else # :all_types or any other value
      Config.benchmarks
    end
  end

  def run_all_benchmarks_of_type(benchmark_type)
    benchmarks = get_benchmarks_for_type(benchmark_type)
    benchmarks.each do |benchmark_id|
      puts "\nRunning #{format_name(benchmark_id)}..."
      selector = ImplementationSelectorService.new(Config.implementations_dir(benchmark_id)) # uses type-based path
      implementations = selector.list_all
      BenchmarkRunnerService.new(benchmark_id, implementations).run
    end
  end

  def run_benchmarks_for_added(added)
    total = added.values.sum(&:size)
    return unless @prompt.yes?("Run benchmarks for newly added implementations? (#{total} added)")

    added.each do |benchmark_id, slugs|
      next if slugs.empty?

      puts "\nRunning #{format_name(benchmark_id)}..."
      implementations = slugs.map do |slug|
        { name: slug, file: "#{Config.implementations_dir(benchmark_id)}/#{slug}.rb" }
      end
      BenchmarkRunnerService.new(benchmark_id, implementations).run
    end
  end
end

Main.new.run
