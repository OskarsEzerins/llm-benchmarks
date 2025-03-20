# LRUCache is a least-recently-used cache implementation that provides O(1) time complexity
# for get and put operations using a combination of a Hash and a doubly-linked list.
#
# Usage:
#   cache = LRUCache.new(CACHE_CAPACITY)
#
#   # Insert or update key-value pairs
#   cache.put(key, value)
#
#   # Retrieve the value associated with a key (returns nil if not found) and marks the key as most recently used
#   cache.get(key)
#
# The cache automatically evicts the least recently used entry when the capacity is exceeded.
class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value for the given key and marks it as recently used.
  # Returns nil if the key is not found.
  def get(key)
    node = @cache[key]
    return nil unless node

    remove(node)
    add_to_front(node)
    node.value
  end

  # Inserts or updates the key with the given value.
  # Moves the key to the front (most recently used) and evicts the least recently used entry if necessary.
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      remove(node)
      add_to_front(node)
    else
      node = Node.new(key, value)
      @cache[key] = node
      add_to_front(node)
      if @cache.size > @capacity
        lru = @tail.prev
        remove(lru)
        @cache.delete(lru.key)
      end
    end
  end

  private

  # Removes a node from the doubly-linked list.
  def remove(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Adds a node right after the head (marking it as most recently used).
  def add_to_front(node)
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end

  # Internal Node class used for the doubly-linked list.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end
end
