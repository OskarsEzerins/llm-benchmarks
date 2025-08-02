# frozen_string_literal: true

# LRUCache implements a Least Recently Used cache with O(1) operations
#
# The cache maintains items in order of most recently used to least recently used.
# When the cache exceeds capacity, the least recently used item is evicted.
#
# Usage:
#   cache = LRUCache.new(capacity)
#   cache.put(key, value) # Add or update a key-value pair
#   cache.get(key)        # Get value for key (nil if not found) and mark as recently used
#
class LRUCache
  # Initialize a new LRU cache with specified capacity
  # @param capacity [Integer] Maximum number of items the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @list = DoublyLinkedList.new
  end

  # Get the value associated with key and mark as most recently used
  # @param key The key to look up
  # @return The value associated with the key, or nil if key not found
  def get(key)
    return nil unless @cache.key?(key)

    # Update access order by moving to the front of the list
    node = @cache[key]
    @list.remove(node)
    @list.add_to_front(node)

    node.value
  end

  # Add or update a key-value pair in the cache
  # If adding would exceed capacity, evict least recently used item
  # @param key The key to store
  # @param value The value to store
  def put(key, value)
    # If key exists, update its value and move to front
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      @list.remove(node)
      @list.add_to_front(node)
      return
    end

    # Evict least recently used if at capacity
    if @cache.size >= @capacity
      key_to_remove = @list.remove_from_end
      @cache.delete(key_to_remove)
    end

    # Add new node to front of list and cache
    node = Node.new(key, value)
    @list.add_to_front(node)
    @cache[key] = node
  end

  private

  # Node for the doubly linked list
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Doubly linked list to track usage order
  class DoublyLinkedList
    def initialize
      @head = nil  # Most recently used
      @tail = nil  # Least recently used
    end

    # Add node to the front (most recently used)
    def add_to_front(node)
      node.next = @head
      node.prev = nil

      @head.prev = node if @head
      @head = node
      @tail = node if @tail.nil?
    end

    # Remove a node from the list
    def remove(node)
      # Connect previous and next nodes
      if node.prev
        node.prev.next = node.next
      else
        @head = node.next
      end

      if node.next
        node.next.prev = node.prev
      else
        @tail = node.prev
      end
    end

    # Remove the last node (least recently used) and return its key
    def remove_from_end
      return nil unless @tail

      key_to_remove = @tail.key
      @tail = @tail.prev

      if @tail
        @tail.next = nil
      else
        @head = nil
      end

      key_to_remove
    end
  end
end
