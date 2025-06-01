class LRUCache
  # Initialize the LRU Cache with a maximum capacity.
  #
  # @param capacity [Integer] The maximum number of elements the cache can hold.
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @order = []
  end

  # Retrieve the value associated with the key and mark it as most recently used.
  #
  # @param key [Object] The key whose value is to be retrieved.
  # @return [Object, nil] The value associated with the key, or nil if not found.
  def get(key)
    if @cache.key?(key)
      update_recently_used(key)
      @cache[key]
    else
      nil
    end
  end

  # Insert or update a key-value pair in the cache. If the cache exceeds capacity,
  # evict the least recently used item.
  #
  # @param key [Object] The key to insert or update.
  # @param value [Object] The value to be associated with the key.
  def put(key, value)
    if @cache.key?(key)
      @cache[key] = value
      update_recently_used(key)
    else
      evict_least_recently_used if @cache.size >= @capacity
      @cache[key] = value
      @order.push(key)
    end
  end

  private

  # Update the order of keys to mark the specified key as most recently used.
  #
  # @param key [Object] The key to be marked as most recently used.
  def update_recently_used(key)
    @order.delete(key)
    @order.push(key)
  end

  # Evict the least recently used item from the cache.
  def evict_least_recently_used
    lru_key = @order.shift
    @cache.delete(lru_key) if lru_key
  end
end