# frozen_string_literal: true

# LRUCache implements a Least Recently Used (LRU) caching mechanism with O(1) operations
# Uses a hash map for fast lookups and a doubly linked list to track access order
class LRUCache
  # Node class for doubly linked list implementation
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
    raise ArgumentError, 'Capacity must be positive' if capacity <= 0

    @capacity = capacity
    @cache = {}
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves value for key and marks as most recently used
  # Returns nil if key not found
  # Time complexity: O(1)
  def get(key)
    return nil unless @cache.key?(key)

    node = @cache[key]
    remove_node(node)
    add_to_front(node)
    node.value
  end

  # Adds or updates key-value pair
  # If capacity exceeded, removes least recently used item
  # Time complexity: O(1) 
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_to_front(node)
    else
      node = Node.new(key, value)
      @cache[key] = node
      add_to_front(node)
      
      if @cache.size > @capacity
        lru_node = @tail.prev
        remove_node(lru_node)
        @cache.delete(lru_node.key)
      end
    end
  end

  private

  # Removes node from current position in linked list
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Adds node to front of linked list (most recently used)
  def add_to_front(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # For debugging/testing
  def to_s
    result = []
    current = @head.next
    while current != @tail
      result << "#{current.key}:#{current.value}"
      current = current.next
    end
    result.join(' -> ')
  end
end