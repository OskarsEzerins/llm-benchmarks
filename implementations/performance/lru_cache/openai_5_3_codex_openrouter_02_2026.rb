# frozen_string_literal: true

# An O(1) LRU (Least Recently Used) cache.
#
# Usage:
#   cache = LRUCache.new(100)
#   cache.put(:a, 1)
#   cache.get(:a) # => 1
#   cache.get(:b) # => nil
#
# LRU behavior:
# - Every successful #get marks the key as most recently used.
# - Every #put marks the key as most recently used.
# - When capacity is exceeded, the least recently used key is evicted.
class LRUCache
  # Internal node for a doubly linked usage list.
  Node = Struct.new(:key, :value, :prev, :next)

  attr_reader :capacity, :size

  def initialize(capacity)
    raise ArgumentError, 'capacity must be a positive Integer' unless capacity.is_a?(Integer) && capacity.positive?

    @capacity = capacity
    @size = 0
    @index = {}

    # Sentinel nodes to avoid edge-condition branching.
    @head = Node.new(nil, nil) # Most recently used side
    @tail = Node.new(nil, nil) # Least recently used side
    @head.next = @tail
    @tail.prev = @head
  end

  # Returns the value for +key+ or nil if not found.
  # Marks +key+ as most recently used when found.
  def get(key)
    node = @index[key]
    return nil unless node

    move_to_front(node)
    node.value
  end

  # Inserts or updates +key+ with +value+.
  # Marks +key+ as most recently used.
  # Evicts the least recently used key if capacity is exceeded.
  def put(key, value)
    node = @index[key]

    if node
      node.value = value
      move_to_front(node)
      return value
    end

    new_node = Node.new(key, value)
    @index[key] = new_node
    add_to_front(new_node)
    @size += 1

    evict_lru! if @size > @capacity
    value
  end

  private

  def move_to_front(node)
    remove_node(node)
    add_to_front(node)
  end

  def add_to_front(node)
    first = @head.next
    node.prev = @head
    node.next = first
    @head.next = node
    first.prev = node
  end

  def remove_node(node)
    previous = node.prev
    following = node.next
    previous.next = following
    following.prev = previous
    node.prev = nil
    node.next = nil
  end

  def evict_lru!
    lru = @tail.prev
    return if lru.equal?(@head)

    remove_node(lru)
    @index.delete(lru.key)
    @size -= 1
  end
end