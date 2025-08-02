class LRUCache
  def initialize(capacity)
    raise ArgumentError, "Capacity must be a positive integer" if capacity <= 0
    @capacity = capacity
    @cache = {}
    @order = []
  end

  def get(key)
    return nil unless @cache.key?(key)

    # Move accessed key to the end (most recently used)
    @order.delete(key)
    @order.push(key)

    @cache[key]
  end

  def put(key, value)
    # Remove existing key if already present to update its position
    if @cache.key?(key)
      @order.delete(key)
    elsif @cache.size >= @capacity
      # Evict least recently used item if cache is full
      lru_key = @order.shift
      @cache.delete(lru_key)
    end

    # Add new key to the end of order list and cache
    @order.push(key)
    @cache[key] = value
  end
end