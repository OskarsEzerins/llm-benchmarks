require 'benchmark'

class LruCacheBenchmark
  CACHE_CAPACITY = 10_000
  NUM_OPERATIONS = 1_000_000
  GET_PROBABILITY = 0.7
  KEY_RANGE = 20_000
  PROGRESS_INTERVAL = 100_000

  def self.run(implementation_path)
    require_relative implementation_path

    cache = LRUCache.new(CACHE_CAPACITY)
    (1..(CACHE_CAPACITY / 2)).each { |i| cache.put(i, i) }

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

    {
      execution_time: time.round(4),
      parameters: {
        "operations" => NUM_OPERATIONS,
        "cache_capacity" => CACHE_CAPACITY,
        "get_probability" => GET_PROBABILITY,
        "key_range" => KEY_RANGE
      }
    }
  end
end
