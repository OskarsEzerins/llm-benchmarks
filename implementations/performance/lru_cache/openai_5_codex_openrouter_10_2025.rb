class LRUCache
  # Represents the LRU (Least Recently Used) cache with fixed maximum capacity.
  #
  # Usage:
  #   cache = LRUCache.new(100)
  #   cache.put(:foo, 1)               #=> 1
  #   cache.put(:bar, 2)               #=> 2
  #   cache.get(:foo)                  #=> 1 (marks :foo as most recently used)
  #   cache.put(:baz, 3)               # evicts least recently used key when capacity exceeded
  #   cache.size                       #=> current number of entries
  #
  # The cache maintains O(1) time complexity for both `#get` and `#put` by combining a hash
  # table for quick lookups with a doubly linked list to track recency of use.
  def initialize(capacity)
    raise ArgumentError, 'capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity.positive?

    @capacity = capacity
    @store = {}
    @head = Node.new # Sentinel node representing the most recently used end.
    @tail = Node.new # Sentinel node representing the least recently used end.

    @head.next = @tail
    @tail.prev = @head
  end

  attr_reader :capacity

  # Returns the number of key-value pairs currently stored in the cache.
  def size
    @store.size
  end

  # Retrieves the value associated with +key+.
  # If present, the entry is promoted to most recently used.
  # Returns +nil+ when the key is not found.
  def get(key)
    node = @store[key]
    return nil unless node

    move_to_front(node)
    node.value
  end

  # Inserts or updates the value associated with +key+.
  # When inserting a new key causes the cache to exceed its capacity, the least recently used
  # entry is evicted. Returns the stored +value+.
  def put(key, value)
    node = @store[key]

    if node
      node.value = value
      move_to_front(node)
    else
      node = Node.new(key, value)
      insert_after(@head, node)
      @store[key] = node
      evict_if_necessary
    end

    value
  end

  private

  Node = Struct.new(:key, :value, :prev, :next, keyword_init: false)

  def move_to_front(node)
    detach(node)
    insert_after(@head, node)
  end

  def evict_if_necessary
    return if @store.size <= @capacity

    lru = @tail.prev
    detach(lru)
    @store.delete(lru.key)
  end

  def detach(node)
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
    node.prev = nil
    node.next = nil
  end

  def insert_after(base, node)
    next_node = base.next
    base.next = node
    node.prev = base
    node.next = next_node
    next_node.prev = node
  end
end