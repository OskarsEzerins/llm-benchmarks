# frozen_string_literal: true

# LRUCache implements a Least Recently Used (LRU) cache with O(1) get and put operations.
#
# Usage:
#   cache = LRUCache.new(capacity)
#   cache.put(key, value) # Insert or update key with value
#   cache.get(key)        # Retrieve value by key, returns nil if not found
#
# The cache evicts the least recently used item when capacity is exceeded.
#
# Internally, it uses a hash map for O(1) access and a doubly linked list to track usage order.
class LRUCache
  # Node represents an entry in the doubly linked list.
  # It holds the key, value, and pointers to prev and next nodes.
  Node = Struct.new(:key, :value, :prev, :next)

  # Initialize the cache with a fixed maximum capacity.
  #
  # @param capacity [Integer] maximum number of items the cache can hold
  # @raise [ArgumentError] if capacity is less than 1
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity.positive?

    @capacity = capacity
    @map = {}
    # Dummy head and tail nodes to avoid edge cases in list operations
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve the value associated with the key.
  # If the key exists, it is marked as most recently used.
  #
  # @param key [Object] the key to look up
  # @return [Object, nil] the value if found, or nil otherwise
  def get(key)
    node = @map[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Insert or update a key-value pair.
  # Marks the key as most recently used.
  # If the cache exceeds capacity, evicts the least recently used item.
  #
  # @param key [Object] the key to insert or update
  # @param value [Object] the value associated with the key
  # @return [void]
  def put(key, value)
    if (node = @map[key])
      node.value = value
      move_to_head(node)
    else
      node = Node.new(key, value)
      @map[key] = node
      add_node(node)
      evict_if_needed
    end
  end

  private

  # Add a new node right after the head (most recently used position)
  #
  # @param node [Node] node to add
  # @return [void]
  def add_node(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Remove a node from the linked list
  #
  # @param node [Node] node to remove
  # @return [void]
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
    node.prev = nil
    node.next = nil
  end

  # Move an existing node to the head (mark as most recently used)
  #
  # @param node [Node] node to move
  # @return [void]
  def move_to_head(node)
    remove_node(node)
    add_node(node)
  end

  # Evict the least recently used node if capacity exceeded
  #
  # @return [void]
  def evict_if_needed
    return unless @map.size > @capacity

    lru = @tail.prev
    remove_node(lru)
    @map.delete(lru.key)
  end
end