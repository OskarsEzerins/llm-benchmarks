# LRUCache implements a Least Recently Used (LRU) cache with O(1) time complexity
# for both get and put operations. It uses a hash table for fast key-based lookups
# and a doubly linked list to maintain the order of usage (most recent at tail,
# least recent at head).
#
# Usage:
#   cache = LRUCache.new(capacity)  # Initialize with maximum capacity
#   cache.put(key, value)           # Insert or update key-value pair
#   value = cache.get(key)          # Retrieve value (or nil if not found) and mark as recently used
#
# LRU Mechanism:
# - On get(key): If key exists, return its value and move the key-value pair to the most recent position.
# - On put(key, value): If key exists, update value and move to most recent. If new and under capacity,
#   add to most recent. If new and at capacity, evict the least recently used (front of list), then add.
# - Eviction removes the least recently used item when capacity is exceeded on insertion.
# - Time: O(1) average for get/put using hash + doubly-linked list.
# - Space: O(capacity) for stored items.
# - Assumes capacity >= 0; for capacity 0, operations effectively do nothing.

class LRUCache
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  def initialize(capacity)
    @capacity = capacity
    @cache = {}  # Hash: key -> Node
    @head = Node.new  # Dummy head (LRU end)
    @tail = Node.new  # Dummy tail (MRU end)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value associated with key, or nil if not found.
  # Moves the accessed node to the tail (most recently used).
  def get(key)
    return nil unless @cache.key?(key)

    node = @cache[key]
    remove_node(node)
    add_to_tail(node)
    node.value
  end

  # Inserts or updates key with value.
  # If new insertion exceeds capacity, evicts the least recently used (head.next).
  # Moves updated/existing keys to tail.
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_to_tail(node)
    else
      node = Node.new(key, value)
      @cache[key] = node

      if @cache.length > @capacity
        lru = @head.next
        remove_node(lru)
        @cache.delete(lru.key)
      end

      add_to_tail(node)
    end
  end

  private

  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  def add_to_tail(node)
    node.next = @tail
    node.prev = @tail.prev
    @tail.prev.next = node
    @tail.prev = node
  end
end