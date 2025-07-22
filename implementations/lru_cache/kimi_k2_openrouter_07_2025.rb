# frozen_string_literal: true

# LRUCache implements a Least-Recently-Used cache with O(1) get and put operations.
#
# Usage:
#   cache = LRUCache.new(3)
#   cache.put(1, 'a')
#   cache.put(2, 'b')
#   cache.get(1)      # => 'a'  (key 1 becomes most-recently-used)
#   cache.put(3, 'c')
#   cache.put(4, 'd') # => evicts key 2
#   cache.get(2)      # => nil
#
class LRUCache
  # Initialize the cache with a fixed positive capacity.
  # @param capacity [Integer] maximum number of key/value pairs allowed
  # @raise [ArgumentError] if capacity is not positive
  def initialize(capacity)
    raise ArgumentError, 'capacity must be > 0' unless capacity.is_a?(Integer) && capacity.positive?

    @capacity = capacity
    @size = 0
    @data = {} # key => ListNode
    @head = ListNode.new # dummy
    @tail = ListNode.new # dummy
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve the value for +key+ and mark it as most-recently-used.
  # @param key [Object]
  # @return [Object, nil] the value or nil if key does not exist
  def get(key)
    node = @data[key]
    return nil unless node

    move_to_front(node)
    node.value
  end

  # Insert or update key/value pair.
  # Evicts the least-recently-used item if capacity is exceeded.
  # @param key [Object]
  # @param value [Object]
  def put(key, value)
    node = @data[key]

    if node
      node.value = value
      move_to_front(node)
    else
      new_node = ListNode.new(key, value)
      add_front(new_node)
      @data[key] = new_node
      @size += 1
      evict_lru if @size > @capacity
    end
  end

  private

  # Internal doubly-linked-list node
  class ListNode
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Remove node from its current position
  def remove(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Add node right after head (most-recently-used spot)
  def add_front(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Move existing node to front (MRU)
  def move_to_front(node)
    remove(node)
    add_front(node)
  end

  # Evict least-recently-used node (at tail.prev)
  def evict_lru
    lru = @tail.prev
    remove(lru)
    @data.delete(lru.key)
    @size -= 1
  end
end