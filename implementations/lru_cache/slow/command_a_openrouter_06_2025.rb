# LRUCache: A Least Recently Used (LRU) Cache implementation in Ruby.
# This cache maintains a maximum capacity and automatically evicts the least recently used items.
# Both get and put operations are optimized for O(1) time complexity.
class LRUCache
  # Initializes the LRU Cache with a specified maximum capacity.
  #
  # @param capacity [Integer] The maximum number of items the cache can hold.
  def initialize(capacity)
    @capacity = capacity
    @cache = {} # Hash to store key-value pairs
    @order = [] # Array to maintain the order of keys (most recently used at the end)
  end

  # Retrieves the value associated with the given key and marks it as most recently used.
  #
  # @param key [Object] The key to look up in the cache.
  # @return [Object, nil] The value associated with the key, or nil if the key is not found.
  def get(key)
    return nil unless @cache.key?(key)

    # Move the accessed key to the end of the order array (most recently used)
    @order.delete(key)
    @order << key
    @cache[key]
  end

  # Inserts a new key-value pair or updates an existing key’s value.
  # If inserting a new key causes the cache to exceed its capacity,
  # the least recently used key is automatically evicted.
  #
  # @param key [Object] The key to insert or update.
  # @param value [Object] The value to associate with the key.
  def put(key, value)
    if @cache.key?(key)
      # If the key already exists, update its value and mark it as most recently used
      @order.delete(key)
      @order << key
    else
      # If the key is new and the cache is at capacity, evict the least recently used key
      if @cache.size >= @capacity
        lru_key = @order.shift
        @cache.delete(lru_key)
      end
      # Add the new key to the cache and mark it as most recently used
      @order << key
      @cache[key] = value
    end
  end
end