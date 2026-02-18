# frozen_string_literal: true

# LRUCache implements a Least Recently Used (LRU) cache with O(1) get and put
# operations.  The cache is initialised with a maximum capacity.  When a new
# key‑value pair is inserted and the cache exceeds this capacity, the least
# recently used entry (the one closest to the tail of the internal linked
# list) is automatically evicted.
#
# Usage:
#   cache = LRUCache.new(3)          # capacity 3
#   cache.put(:a, 1)
#   cache.put(:b, 2)
#   cache.put(:c, 3)
#   cache.get(:a)   # => 1  (marks :a as most recently used)
#   cache.put(:d, 4) # evicts :b (least recently used)
#
# The implementation uses a hash table for O(1) look‑ups and a doubly linked
# list to maintain the LRU order.
class LRUCache
  # Node represents an entry in the doubly linked list.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key   = key
      @value = value
    end
  end

  # Initialise the cache with the given maximum capacity.
  def initialize(capacity)
    raise ArgumentError, "Capacity must be a positive integer" unless capacity.is_a?(Integer) && capacity.positive?

    @capacity = capacity
    @cache = {} # key => Node

    # Sentinel nodes simplify list manipulations.
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve the value for `key`.  If the key exists, it is marked as the most
  # recently used entry.  Returns `nil` if the key is not present.
  def get(key)
    node = @cache[key]
    return nil unless node

    move_to_front(node)
    node.value
  end

  # Insert or update a key‑value pair.  If the key already exists, its value is
  # updated and the key is moved to the most recently used position.  If a new
  # key causes the cache to exceed its capacity, the least recently used entry
  # is evicted.
  def put(key, value)
    node = @cache[key]
    if node
      node.value = value
      move_to_front(node)
    else
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_front(new_node)

      return if @cache.size <= @capacity

      evict_least_recently_used
    end
  end

  private

  # Insert a node right after the head (most recent position).
  def add_to_front(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Remove a node from the linked list.
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Move an existing node to the front (most recently used).
  def move_to_front(node)
    remove_node(node)
    add_to_front(node)
  end

  # Evict the least recently used entry (the node just before the tail).
  def evict_least_recently_used
    lru = @tail.prev
    return if lru == @head # No real nodes to evict.

    @cache.delete(lru.key)
    remove_node(lru)
  end
end