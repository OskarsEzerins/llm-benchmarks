require 'benchmark'

class LRUCache
  # Implements a Least Recently Used (LRU) cache.
  #
  # The cache stores key-value pairs and automatically evicts the least
  # recently used key when the cache reaches its maximum capacity.
  #
  # Usage:
  #   cache = LRUCache.new(5) # Initialize with a capacity of 5
  #   cache.put(1, "a")
  #   cache.put(2, "b")
  #   cache.get(1) # Returns "a" and marks 1 as most recently used
  #   cache.put(3, "c")
  #   cache.put(4, "d")
  #   cache.put(5, "e")
  #   cache.put(6, "f") # Evicts 2 (least recently used)
  #   cache.get(2) # Returns nil
  #   cache.get(1) # Returns "a"
  #
  # LRU Mechanism:
  #   - The cache uses a hash map (Hash) for O(1) key lookups.
  #   - A doubly linked list is used to maintain the order of keys based on
  #     their usage. The most recently used key is at the head of the list,
  #     and the least recently used key is at the tail.
  #   - When a key is accessed (get or put), it's moved to the head of the list.
  #   - When the cache is full, the tail node is removed from the list and
  #     the corresponding key-value pair is removed from the hash map.

  attr_reader :capacity

  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @queue = [] # Doubly linked list implemented as an array for simplicity
  end

  # Retrieves the value associated with the given key.
  # Returns nil if the key is not found.
  # Marks the key as most recently used.
  def get(key)
    if @cache.key?(key)
      move_to_front(key)
      @cache[key]
    else
      nil
    end
  end

  # Inserts a new key-value pair or updates an existing key's value.
  # If inserting a new key causes the cache to exceed its capacity,
  # automatically evicts the least recently used key.
  def put(key, value)
    if @cache.key?(key)
      @cache[key] = value
      move_to_front(key)
    else
      if @cache.size >= @capacity
        evict_lru
      end
      @cache[key] = value
      @queue.unshift(key) # Add to front
    end
  end

  private

  # Moves the given key to the front of the queue (most recently used).
  def move_to_front(key)
    @queue.delete(key)
    @queue.unshift(key)
  end

  # Evicts the least recently used key (tail of the queue).
  def evict_lru
    lru_key = @queue.pop
    @cache.delete(lru_key)
  end
end