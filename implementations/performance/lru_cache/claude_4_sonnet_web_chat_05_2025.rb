# LRU Cache Implementation
#
# This class implements a Least Recently Used (LRU) cache with O(1) time complexity
# for both get and put operations using a combination of a hash table and a doubly
# linked list.
#
# The LRU mechanism works as follows:
# - When a key is accessed (get) or updated (put), it becomes the most recently used
# - When the cache reaches capacity and a new key is added, the least recently used
#   key is automatically evicted
# - The order of usage is maintained using a doubly linked list where the head
#   represents the most recently used item and the tail represents the least recently used
#
# Usage:
#   cache = LRUCache.new(3)
#   cache.put(1, "one")
#   cache.put(2, "two")
#   cache.get(1)           # Returns "one" and marks key 1 as most recently used
#   cache.put(3, "three")
#   cache.put(4, "four")   # Evicts key 2 (least recently used)
#
class LRUCache
  # Internal node class for the doubly linked list
  # Each node contains a key-value pair and pointers to previous and next nodes
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize the LRU cache with the specified capacity
  #
  # @param capacity [Integer] Maximum number of key-value pairs the cache can hold
  # @raise [ArgumentError] if capacity is not a positive integer
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @cache = {}  # Hash table for O(1) key lookup

    # Create dummy head and tail nodes to simplify edge cases
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve the value associated with the given key
  # Marks the key as most recently used if found
  #
  # @param key [Object] The key to look up
  # @return [Object, nil] The value associated with the key, or nil if not found
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the front (most recently used position)
    move_to_front(node)
    node.value
  end

  # Insert or update a key-value pair in the cache
  # If the key already exists, updates its value and marks it as most recently used
  # If the cache is at capacity and a new key is added, evicts the least recently used key
  #
  # @param key [Object] The key to insert or update
  # @param value [Object] The value to associate with the key
  def put(key, value)
    existing_node = @cache[key]

    if existing_node
      # Update existing key
      existing_node.value = value
      move_to_front(existing_node)
    else
      # Insert new key
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_front(new_node)

      # Check if we need to evict the least recently used item
      evict_lru if @cache.size > @capacity
    end
  end

  # Return the current number of items in the cache
  #
  # @return [Integer] Number of key-value pairs currently stored
  def size
    @cache.size
  end

  # Check if the cache is empty
  #
  # @return [Boolean] true if the cache contains no items
  def empty?
    @cache.empty?
  end

  # Check if the cache is at full capacity
  #
  # @return [Boolean] true if the cache cannot accept more items without eviction
  def full?
    @cache.size >= @capacity
  end

  private

  # Move an existing node to the front of the linked list (most recently used position)
  #
  # @param node [Node] The node to move to the front
  def move_to_front(node)
    remove_node(node)
    add_to_front(node)
  end

  # Add a new node to the front of the linked list
  #
  # @param node [Node] The node to add to the front
  def add_to_front(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Remove a node from the linked list
  #
  # @param node [Node] The node to remove
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Evict the least recently used item (node at the tail)
  def evict_lru
    lru_node = @tail.prev
    remove_node(lru_node)
    @cache.delete(lru_node.key)
  end
end
