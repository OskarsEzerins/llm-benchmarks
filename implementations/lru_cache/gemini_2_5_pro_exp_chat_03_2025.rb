# frozen_string_literal: true

# LRUCache implements a Least Recently Used (LRU) cache mechanism.
#
# It stores key-value pairs up to a specified capacity. When the cache is full
# and a new item needs to be inserted, the least recently used item is evicted
# to make space. Both `get` and `put` operations have an average time
# complexity of O(1).
#
# Usage:
#   cache = LRUCache.new(3) # Creates a cache with capacity 3
#   cache.put(:a, 1)        # Cache: {a: 1}
#   cache.put(:b, 2)        # Cache: {a: 1, b: 2}
#   cache.put(:c, 3)        # Cache: {a: 1, b: 2, c: 3}
#   cache.get(:a)           # Returns 1. Cache: {b: 2, c: 3, a: 1} (a is now most recent)
#   cache.put(:d, 4)        # Cache full. Evicts :b (LRU). Cache: {c: 3, a: 1, d: 4}
#   cache.get(:b)           # Returns nil (evicted)
#   cache.put(:c, 33)       # Updates value for :c. Cache: {a: 1, d: 4, c: 33} (c is now most recent)
#
class LRUCache
  # Internal class representing a node in the doubly linked list.
  # Each node holds a key-value pair and pointers to the previous and next nodes.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initializes a new LRUCache with a given capacity.
  #
  # @param capacity [Integer] The maximum number of items the cache can hold.
  #   Must be a positive integer.
  # @raise [ArgumentError] if capacity is not a positive integer.
  def initialize(capacity)
    unless capacity.is_a?(Integer) && capacity.positive?
      raise ArgumentError, 'Capacity must be a positive integer'
    end

    @capacity = capacity
    # @cache stores key -> Node mappings for O(1) lookup.
    @cache = {}
    # @head and @tail are dummy nodes for the doubly linked list, simplifying
    # list operations (add/remove).
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value associated with the given key from the cache.
  # If the key is found, it marks the item as the most recently used.
  #
  # @param key The key to look up.
  # @return The value associated with the key, or nil if the key is not found.
  # @complexity O(1) average time.
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the front of the list to mark it as most recently used.
    _move_to_front(node)
    node.value
  end

  # Inserts or updates a key-value pair in the cache.
  # If the key already exists, its value is updated, and it's marked as the
  # most recently used.
  # If the key is new and the cache is at full capacity, the least recently
  # used item is evicted before inserting the new item. The new item is always
  # marked as the most recently used.
  #
  # @param key The key to insert or update.
  # @param value The value associated with the key.
  # @complexity O(1) average time.
  def put(key, value)
    node = @cache[key]

    if node
      # Key exists: Update value and move to front.
      node.value = value
      _move_to_front(node)
    else
      # Key is new: Check capacity and evict if necessary.
      _evict_lru if @cache.size >= @capacity

      # Create new node and add it.
      new_node = Node.new(key, value)
      @cache[key] = new_node
      _add_to_front(new_node)
    end
  end

  # Provides a string representation of the cache content for debugging.
  # Shows the order from most recently used (front) to least recently used (back).
  #
  # @return [String] A string representation of the cache.
  def to_s
    elements = []
    current = @head.next
    while current != @tail
      elements << "#{current.key}:#{current.value}"
      current = current.next
    end
    "LRUCache(#{elements.join(', ')})"
  end

  # Returns the current number of items in the cache.
  #
  # @return [Integer] The current size of the cache.
  def size
    @cache.size
  end

  # Returns the maximum capacity of the cache.
  #
  # @return [Integer] The maximum capacity.
  attr_reader :capacity

  private

  # Removes a node from the doubly linked list.
  # Connects the node's previous and next neighbours directly.
  # @param node [Node] The node to remove.
  # @complexity O(1).
  def _remove_node(node)
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
  end

  # Adds a node to the front of the doubly linked list (right after @head).
  # This signifies the node as the most recently used.
  # @param node [Node] The node to add.
  # @complexity O(1).
  def _add_to_front(node)
    # Wire node into list right after head
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end

  # Moves an existing node to the front of the doubly linked list.
  # This is equivalent to removing the node and then adding it to the front.
  # @param node [Node] The node to move.
  # @complexity O(1).
  def _move_to_front(node)
    _remove_node(node)
    _add_to_front(node)
  end

  # Evicts the least recently used item from the cache.
  # This involves removing the node just before the @tail dummy node from
  # both the linked list and the @cache hash.
  # @complexity O(1).
  def _evict_lru
    lru_node = @tail.prev
    return unless lru_node && lru_node != @head # Ensure there's something to evict

    _remove_node(lru_node)
    @cache.delete(lru_node.key)
  end
end
