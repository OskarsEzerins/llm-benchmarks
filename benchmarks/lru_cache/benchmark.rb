require 'benchmark'

class LruCacheBenchmark
  CACHE_CAPACITY = 100_000
  NUM_OPERATIONS = 5_000_000
  GET_PROBABILITY = 0.8
  KEY_RANGE = 500_000
  HOT_KEY_RANGE = 1000
  HOT_KEY_PROBABILITY = 0.6
  PROGRESS_INTERVAL = 500_000

  def self.run(implementation_path)
    require_relative implementation_path

    cache = LRUCache.new(CACHE_CAPACITY)
    (1..(CACHE_CAPACITY / 2)).each { |i| cache.put(i, i) }

    puts "Starting heavy workload simulation with #{NUM_OPERATIONS} operations..."
    time = Benchmark.realtime do
      NUM_OPERATIONS.times do |_i|
        key = if rand < HOT_KEY_PROBABILITY
                rand(1..HOT_KEY_RANGE)
              else
                rand(HOT_KEY_RANGE + 1..KEY_RANGE)
              end

        if rand < GET_PROBABILITY
          cache.get(key)
        else
          value = rand(1..1_000_000)
          cache.put(key, value)
        end
      end
    end

    time.round(4)
  end
end
