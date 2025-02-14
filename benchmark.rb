#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require
require 'benchmark'
require 'terminal-table'
require_relative 'lib/services/results_display_service'
require_relative 'lib/services/results_service'

RESULTS_FILE = "results/lru_cache.json"
CACHE_CAPACITY = 10_000
NUM_OPERATIONS = 1_000_000
GET_PROBABILITY = 0.7
KEY_RANGE = 20_000
PROGRESS_INTERVAL = 100_000

implementations_dir = "implementations/lru_cache"
implementations = Dir.glob("#{implementations_dir}/*.rb").map { |f| File.basename(f, '.rb') }

if implementations.empty?
  puts "Error: No implementations found in #{implementations_dir}"
  exit 1
end

prompt = TTY::Prompt.new
implementation = ARGV[0]

if implementation.nil?
  implementation = prompt.select("Choose an LRU Cache implementation:", implementations)
end

implementation_file = "#{implementations_dir}/#{implementation}.rb"
unless File.exist?(implementation_file)
  puts "Error: Implementation '#{implementation}' not found"
  exit 1
end

require_relative implementation_file

cache = LRUCache.new(CACHE_CAPACITY)

(1..(CACHE_CAPACITY / 2)).each { |i| cache.put(i, i) }

puts "Running benchmark with implementation: #{implementation}"
puts "Starting heavy workload simulation with #{NUM_OPERATIONS} operations..."
time = Benchmark.realtime do
  NUM_OPERATIONS.times do |i|
    key = rand(1..KEY_RANGE)
    rand < GET_PROBABILITY ? cache.get(key) : cache.put(key, rand(1..100_000))

    if (i + 1) % PROGRESS_INTERVAL == 0
      progress = ((i + 1).to_f / NUM_OPERATIONS * 100).round(1)
      puts "Progress: #{progress}% (#{i + 1} operations)"
    end
  end
end

execution_time = time.round(4)
puts "Completed #{NUM_OPERATIONS} operations in #{execution_time} seconds."

results_service = ResultsService.new(RESULTS_FILE)
parameters = {
  "operations" => NUM_OPERATIONS,
  "cache_capacity" => CACHE_CAPACITY,
  "get_probability" => GET_PROBABILITY,
  "key_range" => KEY_RANGE
}

results = results_service.add_result(implementation, execution_time, parameters)
ResultsDisplayService.display(results, implementation)
