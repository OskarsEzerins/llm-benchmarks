# frozen_string_literal: true

# LRUCache implements a Least Recently Used (LRU) cache.
#
# The cache stores key-value pairs with a fixed maximum capacity. When the
# cache exceeds this capacity, it automatically evicts the least recently used
# item.
#
# Usage:
#   cache = LRUCache.new(max_capacity)
#   cache.put(key, value) # Insert or update a key-value pair.
#   value = cache.get(key) # Returns the value associated with key or nil.
#
# Both #get and #put operations run in O(1) time.
#
# Internally, this cache uses a combination of a hash map and a doubly linked list.
# The hash map provides O(1) access to nodes, while the linked list maintains usage order.
class LRUCache
  # Node is a helper class representing an element in a doubly linked list.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize an LRUCache with a max capacity.
  # @param capacity [Integer] maximum number of items cache can hold
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity.positive?

    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil) # Dummy head
    @tail = Node.new(nil, nil) # Dummy tail
    @head.next = @tail
    @tail.prev = @head
  end

  # Get value for key, marking the key as most recently used.
  # @param key [Object] key to look up
  # @return [Object, nil] value if found or nil if not present
  def get(key)
    node = @cache[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Insert or update the key-value pair.
  # Evicts least recently used item if capacity exceeded.
  # @param key [Object]
  # @param value [Object]
  # @return [void]
  def put(key, value)
    if (node = @cache[key])
      node.value = value
      move_to_head(node)
    else
      node = Node.new(key, value)
      @cache[key] = node
      add_node(node)
      evict_if_needed
    end
    nil
  end

  private

  # Adds a new node right after head (most recently used position)
  def add_node(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Removes a node from the linked list
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
    node.prev = nil
    node.next = nil
  end

  # Moves an existing node to the head (most recently used position)
  def move_to_head(node)
    remove_node(node)
    add_node(node)
  end

  # Removes the least recently used node (before tail) when capacity exceeded
  def evict_if_needed
    return if @cache.size <= @capacity

    lru = @tail.prev
    return if lru == @head # safety check; should never happen

    remove_node(lru)
    @cache.delete(lru.key)
  end
end
