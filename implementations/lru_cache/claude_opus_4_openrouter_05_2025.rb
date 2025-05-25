# LRU (Least Recently Used) Cache implementation
#
# This cache automatically evicts the least recently used items when capacity is exceeded.
# Both get and put operations run in O(1) time complexity.
#
# Usage:
#   cache = LRUCache.new(3)
#   cache.put("a", 1)
#   cache.put("b", 2)
#   cache.put("c", 3)
#   cache.get("a")     # => 1 (marks "a" as most recently used)
#   cache.put("d", 4)  # evicts "b" (least recently used)
#   cache.get("b")     # => nil
#
# Implementation details:
# - Uses a Hash for O(1) key-value lookups
# - Uses a doubly-linked list to track access order
# - Most recently used items are moved to the tail
# - Least recently used items are at the head
class LRUCache
  # Internal node class for the doubly-linked list
  # @api private
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize a new LRU Cache
  # @param capacity [Integer] maximum number of key-value pairs the cache can hold
  # @raise [ArgumentError] if capacity is not a positive integer
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @cache = {}
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve a value from the cache
  # @param key [Object] the key to look up
  # @return [Object, nil] the value associated with the key, or nil if not found
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move to tail (mark as most recently used)
    remove_node(node)
    add_to_tail(node)

    node.value
  end

  # Store or update a key-value pair in the cache
  # @param key [Object] the key to store
  # @param value [Object] the value to associate with the key
  # @return [Object] the stored value
  def put(key, value)
    if @cache.key?(key)
      # Update existing key
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_to_tail(node)
    else
      # Add new key
      node = Node.new(key, value)
      @cache[key] = node
      add_to_tail(node)

      # Evict LRU if over capacity
      if @cache.size > @capacity
        lru_node = @head.next
        remove_node(lru_node)
        @cache.delete(lru_node.key)
      end
    end

    value
  end

  private

  # Remove a node from its current position in the linked list
  # @param node [Node] the node to remove
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Add a node to the tail of the linked list (most recently used position)
  # @param node [Node] the node to add
  def add_to_tail(node)
    node.prev = @tail.prev
    node.next = @tail
    @tail.prev.next = node
    @tail.prev = node
  end
end