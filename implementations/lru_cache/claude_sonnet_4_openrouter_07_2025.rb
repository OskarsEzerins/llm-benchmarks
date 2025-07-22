# LRUCache - Least Recently Used Cache Implementation
#
# This cache maintains a maximum capacity and automatically evicts the least
# recently used items when the capacity is exceeded. Both get and put operations
# run in O(1) time complexity using a combination of a hash table and doubly
# linked list.
#
# Usage:
#   cache = LRUCache.new(3)
#   cache.put("key1", "value1")
#   cache.put("key2", "value2")
#   cache.get("key1")  # Returns "value1" and marks key1 as most recently used
#   cache.put("key3", "value3")
#   cache.put("key4", "value4")  # This will evict the least recently used item
#
# LRU Mechanism:
# - When an item is accessed (get) or updated (put), it becomes most recently used
# - When capacity is exceeded, the least recently used item is automatically removed
# - The cache maintains access order using a doubly linked list for O(1) operations
class LRUCache
  # Internal node structure for the doubly linked list
  # Each node represents a cache entry with key-value pair and pointers
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize the LRU cache with specified capacity
  #
  # @param capacity [Integer] Maximum number of items the cache can hold
  # @raise [ArgumentError] if capacity is not a positive integer
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @cache = {}  # Hash table for O(1) key lookup
    
    # Create dummy head and tail nodes to simplify list operations
    # This eliminates edge cases when adding/removing nodes
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve value for the given key and mark as most recently used
  #
  # @param key [Object] The key to look up
  # @return [Object, nil] The value associated with the key, or nil if not found
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move accessed node to front (most recently used position)
    move_to_front(node)
    node.value
  end

  # Insert or update a key-value pair in the cache
  #
  # If the key already exists, updates its value and marks as most recently used.
  # If the key is new and cache is at capacity, evicts the least recently used item.
  #
  # @param key [Object] The key to insert or update
  # @param value [Object] The value to associate with the key
  def put(key, value)
    existing_node = @cache[key]
    
    if existing_node
      # Update existing key's value and mark as most recently used
      existing_node.value = value
      move_to_front(existing_node)
    else
      # Create new node and add to cache
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_front(new_node)
      
      # Evict least recently used item if capacity exceeded
      evict_lru if @cache.size > @capacity
    end
  end

  # Get current number of items in cache
  #
  # @return [Integer] Current cache size
  def size
    @cache.size
  end

  # Check if cache is empty
  #
  # @return [Boolean] true if cache is empty, false otherwise
  def empty?
    @cache.empty?
  end

  # Check if cache is at full capacity
  #
  # @return [Boolean] true if cache is full, false otherwise
  def full?
    @cache.size >= @capacity
  end

  private

  # Add node right after the head (most recently used position)
  #
  # @param node [Node] The node to add to front
  def add_to_front(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Remove node from its current position in the linked list
  #
  # @param node [Node] The node to remove
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Move existing node to front (most recently used position)
  #
  # @param node [Node] The node to move to front
  def move_to_front(node)
    remove_node(node)
    add_to_front(node)
  end

  # Remove and return the least recently used node (right before tail)
  #
  # @return [Node] The evicted node
  def evict_lru
    lru_node = @tail.prev
    remove_node(lru_node)
    @cache.delete(lru_node.key)
    lru_node
  end
end