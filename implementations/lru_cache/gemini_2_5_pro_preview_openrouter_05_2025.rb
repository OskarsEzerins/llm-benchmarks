# frozen_string_literal: true

# = LRUCache
#
# A Least Recently Used (LRU) Cache implementation.
#
# The cache stores key-value pairs up to a specified maximum capacity.
# When a `get` operation is performed on a key, that key is marked as
# most recently used.
# When a `put` operation inserts a new key and the cache is at capacity,
# the least recently used key is evicted to make space. If the key
# already exists, its value is updated, and it's marked as most
# recently used.
#
# Both `get` and `put` operations aim for O(1) time complexity.
# This is achieved by using a Hash for quick key lookups (average O(1))
# and a Doubly Linked List to maintain the order of usage (O(1) for
# additions, removals, and moves).
#
# == Usage
#
#   cache = LRUCache.new(3) # Cache with capacity of 3
#
#   cache.put(:a, 1) # Cache: {a:1} (MRU: a)
#   cache.put(:b, 2) # Cache: {b:2, a:1} (MRU: b)
#   cache.put(:c, 3) # Cache: {c:3, b:2, a:1} (MRU: c)
#   # Order of items from MRU to LRU: c, b, a
#
#   cache.get(:a)    # Returns 1.
#   # Order of items from MRU to LRU: a, c, b
#
#   cache.put(:d, 4) # :b is evicted (LRU).
#   # Order of items from MRU to LRU: d, a, c
#
#   cache.get(:b)    # Returns nil (evicted)
#
class LRUCache
  # Internal Node class for the Doubly Linked List.
  # Each node stores a key-value pair and pointers to the previous and next nodes.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end
  private_constant :Node # Make Node class private to LRUCache

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
    @cache = {} # Hash: key => Node for O(1) lookup
    @head = Node.new(nil, nil) # Dummy head of the Doubly Linked List
    @tail = Node.new(nil, nil) # Dummy tail of the Doubly Linked List
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value associated with the given key.
  # Marks the key as most recently used if found.
  #
  # @param key [Object] The key to look up.
  # @return [Object, nil] The value associated with the key, or nil if the key is not found.
  #   Time complexity: O(1) on average.
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the MRU position in the list
    move_node_to_mru_list(node)
    node.value
  end

  # Inserts or updates a key-value pair.
  # If inserting a new key and the cache is at its capacity,
  # the least recently used key is evicted.
  # If the key already exists, its value is updated, and it's marked as
  # most recently used.
  #
  # @param key [Object] The key to insert or update.
  # @param value [Object] The value associated with the key.
  # @return [Object] The value that was put into the cache.
  #   Time complexity: O(1) on average.
  def put(key, value)
    node = @cache[key]

    if node
      # Key exists: update value and mark as MRU
      node.value = value
      move_node_to_mru_list(node)
    else
      # Key does not exist: insert new node
      # Evict LRU item if cache is full
      if @cache.size >= @capacity
        lru_node = @tail.prev # LRU node is the one before the dummy tail
        remove_node_from_list(lru_node)
        @cache.delete(lru_node.key)
      end

      # Add new node to cache and mark as MRU
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_node_to_mru_list(new_node)
    end
    value # Return the put value, a common convention
  end

  private

  # Adds a node to the "Most Recently Used" position in the Doubly Linked List.
  # The MRU position is right after the dummy @head.
  # @param node [Node] The node to add.
  def add_node_to_mru_list(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Removes a node from its current position in the Doubly Linked List.
  # @param node [Node] The node to remove.
  def remove_node_from_list(node)
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
  end

  # Moves an existing node to the "Most Recently Used" position in the list.
  # This involves removing it from its current position and adding it to the MRU position.
  # @param node [Node] The node to move.
  def move_node_to_mru_list(node)
    remove_node_from_list(node)
    add_node_to_mru_list(node)
  end
end