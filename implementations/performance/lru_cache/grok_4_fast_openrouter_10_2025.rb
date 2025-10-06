# LRUCache implements a Least Recently Used (LRU) cache using a hash for O(1) lookups and a
# doubly linked list for O(1) order maintenance. This ensures both get and put operations
# are O(1) time complexity.
#
# The LRU mechanism works as follows:
# - The cache tracks the order of usage with a doubly linked list: the head represents the
#   most recently used item, and the tail represents the least recently used item.
# - On get(key): If the key exists, return its value and move it to the most recently used
#   position (after the head). If not found, return nil.
# - On put(key, value): If the key exists, update its value and move it to the most recently
#   used position. If new, add it to the most recently used position. If the cache exceeds
#   capacity after adding a new key, evict the least recently used item (before the tail)
#   and remove it from the hash.
#
# Sentinel (dummy) nodes are used for the head and tail to simplify boundary conditions.
#
# Usage:
#   cache = LRUCache.new(capacity)  # capacity is the maximum number of key-value pairs
#   cache.put(key, value)           # Insert or update key-value pair
#   value = cache.get(key)          # Returns value or nil if key not found
#
# Example:
#   cache = LRUCache.new(2)
#   cache.put(1, 1)
#   cache.put(2, 2)
#   puts cache.get(1)  # => 1 (moves 1 to MRU)
#   cache.put(3, 3)    # Evicts 2 (LRU)
#   puts cache.get(2)  # => nil
#
# This implementation uses only Ruby's standard library (Hash, custom Node class).
class LRUCache
  # Inner Node class for the doubly linked list.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  def initialize(capacity)
    raise ArgumentError, "Capacity must be positive" if capacity <= 0

    @capacity = capacity
    @cache = {}    # Hash: key -> Node for O(1) access
    @head = Node.new  # Dummy head: points to MRU
    @tail = Node.new  # Dummy tail: points to LRU
    @head.next = @tail
    @tail.prev = @head
    @size = 0
  end

  # Get the value for key and mark as most recently used (O(1)).
  # Returns nil if key not found.
  def get(key)
    return nil unless @cache.key?(key)

    node = @cache[key]
    remove_node(node)
    add_node_to_head(node)
    node.value
  end

  # Put key-value pair, updating if exists or inserting new.
  # If new insertion exceeds capacity, evict LRU (O(1)).
  def put(key, value)
    if @cache.key?(key)
      # Update existing
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_node_to_head(node)
    else
      # Insert new
      node = Node.new(key, value)
      @cache[key] = node
      add_node_to_head(node)
      @size += 1

      # Evict LRU if over capacity
      if @size > @capacity
        lru_node = @tail.prev
        remove_node(lru_node)
        @cache.delete(lru_node.key)
        @size -= 1
      end
    end
  end

  private

  # Add node after head (MRU position).
  def add_node_to_head(node)
    # Insert after head
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Remove node from the list.
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end
end