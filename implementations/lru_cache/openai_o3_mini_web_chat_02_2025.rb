class LRUCache
  # The LRUCache is a Least Recently Used cache implementation.
  #
  # It uses a combination of a Hash for O(1) access time and a doubly linked list
  # to keep track of the usage order.
  #
  # Usage:
  #   cache = LRUCache.new(capacity)
  #   cache.put(key, value) # Inserts or updates the key-value pair.
  #   cache.get(key)        # Retrieves the value for the key (or nil if not found)
  #                         # and marks the key as most recently used.
  #
  # When the cache exceeds the maximum capacity, the least recently used item is evicted.

  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  def get(key)
    node = @cache[key]
    return nil unless node

    remove(node)
    insert_after_head(node)
    node.value
  end

  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      remove(node)
      insert_after_head(node)
    else
      if @cache.size >= @capacity
        lru = @tail.prev
        remove(lru)
        @cache.delete(lru.key)
      end
      node = Node.new(key, value)
      @cache[key] = node
      insert_after_head(node)
    end
    nil
  end

  private

  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  def remove(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  def insert_after_head(node)
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end
end
