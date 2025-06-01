# frozen_string_literal: true

# LRUCache implements a Least Recently Used (LRU) caching mechanism with O(1) operations
# The cache maintains both the key-value pairs and the access order of elements
# When capacity is reached, the least recently used item is evicted
class LRUCache
  # Initialize new cache with specified maximum capacity
  # @param capacity [Integer] Maximum number of key-value pairs the cache can hold
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be positive' if capacity <= 0

    @capacity = capacity
    @cache = {}
    @access_order = DoublyLinkedList.new
    @node_lookup = {}
  end

  # Retrieve value for given key and mark as most recently used
  # @param key Key to look up
  # @return [Object, nil] Value associated with key, or nil if not found
  def get(key)
    return nil unless @cache.key?(key)

    node = @node_lookup[key]
    @access_order.move_to_front(node)
    @cache[key]
  end

  # Insert or update key-value pair, marking as most recently used
  # If at capacity, evicts least recently used item
  # @param key Key to insert/update
  # @param value Value to store
  def put(key, value)
    if @cache.key?(key)
      @cache[key] = value
      @access_order.move_to_front(@node_lookup[key])
      return
    end

    if @cache.size >= @capacity
      lru_key = @access_order.remove_last
      @cache.delete(lru_key)
      @node_lookup.delete(lru_key)
    end

    @cache[key] = value
    node = @access_order.add_front(key)
    @node_lookup[key] = node
  end

  private

  # Internal node class for doubly-linked list implementation
  class Node
    attr_accessor :key, :prev, :next

    def initialize(key)
      @key = key
      @prev = nil
      @next = nil
    end
  end

  # Internal doubly-linked list to track access order
  class DoublyLinkedList
    def initialize
      @head = Node.new(nil) # Sentinel head
      @tail = Node.new(nil) # Sentinel tail
      @head.next = @tail
      @tail.prev = @head
    end

    def add_front(key)
      node = Node.new(key)
      node.next = @head.next
      node.prev = @head
      @head.next.prev = node
      @head.next = node
      node
    end

    def move_to_front(node)
      remove_node(node)
      node.next = @head.next
      node.prev = @head
      @head.next.prev = node
      @head.next = node
    end

    def remove_last
      return nil if @tail.prev == @head

      node = @tail.prev
      key = node.key
      remove_node(node)
      key
    end

    private

    def remove_node(node)
      node.prev.next = node.next
      node.next.prev = node.prev
    end
  end
end