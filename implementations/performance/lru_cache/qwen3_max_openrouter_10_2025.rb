# frozen_string_literal: true

##
# LRUCache implements a Least Recently Used (LRU) cache with O(1) time complexity
# for both get and put operations. It automatically evicts the least recently
# used items when the cache exceeds its maximum capacity.
#
# The cache uses a doubly linked list to maintain the order of usage and a hash
# table for O(1) lookups. The most recently used items are kept at the head of
# the list, while the least recently used items are at the tail.
#
# Usage example:
#   cache = LRUCache.new(100)
#   cache.put("key1", "value1")
#   value = cache.get("key1")  # Returns "value1"
#   cache.put("key2", "value2")
#   # When capacity is exceeded, the least recently used item is automatically removed
class LRUCache
  ##
  # Node class for the doubly linked list that tracks usage order
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # @return [Integer] the maximum capacity of the cache
  attr_reader :capacity

  ##
  # Initializes a new LRU Cache with the specified capacity
  #
  # @param capacity [Integer] the maximum number of items the cache can hold
  # @raise [ArgumentError] if capacity is not a positive integer
  def initialize(capacity)
    raise ArgumentError, "Capacity must be a positive integer" unless capacity.positive?

    @capacity = capacity
    @cache = {}
    @head = nil
    @tail = nil
  end

  ##
  # Retrieves the value associated with the given key
  #
  # @param key the key to look up
  # @return the value associated with the key, or nil if not found
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the head (most recently used)
    move_to_head(node)
    node.value
  end

  ##
  # Inserts or updates a key-value pair in the cache
  #
  # If the key already exists, its value is updated and it becomes the most
  # recently used. If the key doesn't exist and adding it would exceed capacity,
  # the least recently used item is evicted before insertion.
  #
  # @param key the key to insert or update
  # @param value the value to associate with the key
  def put(key, value)
    if @cache.key?(key)
      # Update existing key
      node = @cache[key]
      node.value = value
      move_to_head(node)
    else
      # Insert new key
      if @cache.size >= @capacity
        # Evict least recently used item (tail)
        @cache.delete(@tail.key)
        remove_tail
      end

      # Add new node to head
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_head(new_node)
    end
  end

  private

  ##
  # Adds a node to the head of the doubly linked list
  #
  # @param node [Node] the node to add to the head
  def add_to_head(node)
    if @head.nil?
      # Empty list
      @head = node
      @tail = node
    else
      # Non-empty list
      node.next = @head
      @head.prev = node
      @head = node
    end
  end

  ##
  # Removes the tail node from the doubly linked list
  def remove_tail
    return if @tail.nil?

    if @head == @tail
      # Only one node
      @head = nil
      @tail = nil
    else
      # Multiple nodes
      @tail = @tail.prev
      @tail.next = nil
    end
  end

  ##
  # Moves a node to the head of the doubly linked list
  #
  # @param node [Node] the node to move to the head
  def move_to_head(node)
    return if @head == node

    # Remove node from its current position
    if node == @tail
      @tail = node.prev
      @tail.next = nil
    else
      node.prev.next = node.next
      node.next.prev = node.prev
    end

    # Add to head
    node.prev = nil
    node.next = @head
    @head.prev = node
    @head = node
  end
end