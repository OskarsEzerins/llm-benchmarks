#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require

require 'benchmark'

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

CACHE_CAPACITY = 10_000
NUM_OPERATIONS = 1_000_000
GET_PROBABILITY = 0.7
KEY_RANGE = 20_000
PROGRESS_INTERVAL = 100_000

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

puts "Completed #{NUM_OPERATIONS} operations in #{time.round(2)} seconds."
