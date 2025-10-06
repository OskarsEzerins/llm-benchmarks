class LRUCache
  # == Overview
  # LRUCache is a fixed-size, in-memory cache that evicts the least recently
  # used entry when it reaches its capacity. Cache lookups (get) and inserts
  # (put) both execute in O(1) time by combining a Ruby Hash for constant-time
  # key access with a custom doubly linked list that maintains access order.
  #
  # == Usage
  #   cache = LRUCache.new(100)
  #   cache.put(:foo, :bar)
  #   cache.get(:foo) # => :bar
  #
  # The most recently accessed entries are kept near the head of the internal
  # list, while the least recently used entry resides near the tail and will be
  # evicted when capacity is exceeded.
  attr_reader :capacity, :size

  Node = Struct.new(:key, :value, :prev, :next)

  def initialize(capacity)
    unless capacity.is_a?(Integer) && capacity.positive?
      raise ArgumentError, "capacity must be a positive integer"
    end

    @capacity = capacity
    @map = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
    @size = 0
  end

  def get(key)
    node = @map[key]
    return nil unless node

    move_to_front(node)
    node.value
  end

  def put(key, value)
    node = @map[key]
    if node
      node.value = value
      move_to_front(node)
    else
      node = Node.new(key, value)
      @map[key] = node
      attach(node)
      @size += 1
      evict_if_needed
    end
    value
  end

  private

  def attach(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  def detach(node)
    node.prev.next = node.next
    node.next.prev = node.prev
    node.prev = nil
    node.next = nil
  end

  def move_to_front(node)
    detach(node)
    attach(node)
  end

  def evict_if_needed
    return unless @size > @capacity

    lru = @tail.prev
    detach(lru)
    @map.delete(lru.key)
    @size -= 1
  end
end