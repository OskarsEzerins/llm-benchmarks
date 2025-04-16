# LRUCache implements a fixed-size least-recently-used cache.
# Uses Ruby’s Hash to maintain insertion/access order:
#  - On get/put, key is moved to the end (most recently used).
#  - When capacity is exceeded, the oldest entry (front of the hash) is evicted.
class LRUCache
  # Create a new LRUCache.
  #
  # @param max_capacity [Integer] maximum entries allowed (must be > 0)
  # @raise [ArgumentError] if max_capacity is not a positive integer
  def initialize(max_capacity)
    unless max_capacity.is_a?(Integer) && max_capacity > 0
      raise ArgumentError, "Capacity must be a positive integer"
    end

    @max_capacity = max_capacity
    @cache = {}
  end

  # Retrieve value for key, marking it as most recently used.
  #
  # @param key [Object] lookup key
  # @return [Object, nil] associated value or nil if missing
  def get(key)
    return nil unless @cache.key?(key)

    value = @cache.delete(key)
    @cache[key] = value
    value
  end

  # Insert or update key-value pair. Evict LRU entry if capacity exceeded.
  #
  # @param key [Object] key to insert/update
  # @param value [Object] value to associate
  # @return [void]
  def put(key, value)
    if @cache.key?(key)
      @cache.delete(key)
    elsif @cache.size >= @max_capacity
      @cache.shift
    end

    @cache[key] = value
    nil
  end
end
