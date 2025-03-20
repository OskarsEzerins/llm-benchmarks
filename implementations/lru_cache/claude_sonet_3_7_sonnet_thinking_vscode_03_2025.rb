# LRUCache implements a Least Recently Used (LRU) caching mechanism.
#
# The cache has a fixed capacity and automatically evicts the least recently
# used items when the capacity is exceeded. Both get and put operations have
# O(1) time complexity.
#
# Usage:
#   cache = LRUCache.new(2)  # Create a cache with capacity 2
#   cache.put(1, 1)          # Store key-value pair (1, 1)
#   cache.put(2, 2)          # Store key-value pair (2, 2)
#   cache.get(1)             # Returns 1 (and marks key 1 as most recently used)
#   cache.put(3, 3)          # Evicts key 2, stores key-value pair (3, 3)
#   cache.get(2)             # Returns nil (key 2 was evicted)
class LRUCache
  # Node for the doubly-linked list
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize the LRU Cache with a fixed capacity
  # @param capacity [Integer] Maximum number of items the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @size = 0
    @cache = {}  # Hash to store key -> node mappings

    # Initialize dummy head and tail nodes for the doubly-linked list
    @head = Node.new  # Most recently used
    @tail = Node.new  # Least recently used
    @head.next = @tail
    @tail.prev = @head
  end

  # Get the value for a key and mark it as most recently used
  # @param key Key to look up
  # @return Value associated with key, or nil if not found
  def get(key)
    if @cache.key?(key)
      # Found the key, move to front (most recently used)
      node = @cache[key]
      move_to_front(node)
      return node.value
    end
    nil  # Key not found
  end

  # Insert or update a key-value pair in the cache
  # If inserting a new key would exceed capacity, the least recently used key is evicted
  # @param key Key to insert or update
  # @param value Value to associate with the key
  def put(key, value)
    if @cache.key?(key)
      # Update existing key
      node = @cache[key]
      node.value = value
      move_to_front(node)
    else
      # Insert new key
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_front(new_node)
      @size += 1

      # Evict least recently used if capacity exceeded
      if @size > @capacity
        remove_lru
        @size -= 1
      end
    end
  end

  private

  # Add node right after head
  def add_to_front(node)
    node.next = @head.next
    node.next.prev = node
    @head.next = node
    node.prev = @head
  end

  # Remove node from the linked list
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Move existing node to front (most recently used)
  def move_to_front(node)
    remove_node(node)
    add_to_front(node)
  end

  # Remove the least recently used node (the one before tail)
  def remove_lru
    lru = @tail.prev
    remove_node(lru)
    @cache.delete(lru.key)
  end
end
