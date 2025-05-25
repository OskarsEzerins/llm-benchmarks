# LRUCache implements a fixed-capacity cache with least-recently-used eviction policy.
#
# Usage:
#   cache = LRUCache.new(3)
#   cache.put(1, 'one')
#   cache.get(1)      # => 'one'
#   cache.put(2, 'two')
#   cache.put(3, 'three')
#   cache.put(4, 'four')  # evicts key 1
#   cache.get(1)      # => nil
#
# The cache achieves O(1) get and put by combining a hash map for lookups
# and a doubly linked list to track usage order (most recent at head,
# least recent at tail).
class LRUCache
  Node = Struct.new(:key, :value, :prev, :next)

  # Initialize the cache with a given maximum capacity (> 0).
  #
  # @param capacity [Integer] the maximum number of entries to hold
  # @raise [ArgumentError] if capacity is not positive
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be > 0' unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @map = {}             # key => node
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve the value for the given key, marking it as most recently used.
  #
  # @param key [Object] the key to look up
  # @return [Object, nil] the associated value or nil if not found
  def get(key)
    node = @map[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Insert or update the key-value pair. If the cache exceeds capacity,
  # evict the least recently used entry.
  #
  # @param key [Object] the key to insert/update
  # @param value [Object] the value to associate
  # @return [void]
  def put(key, value)
    if (node = @map[key])
      node.value = value
      move_to_head(node)
    else
      evict_if_needed
      new_node = Node.new(key, value)
      @map[key] = new_node
      add_to_head(new_node)
    end
  end

  private

  # Remove a node from its current position in the linked list.
  def remove(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Add a node right after the head sentinel.
  def add_to_head(node)
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end

  # Move an existing node to the head (mark as most recently used).
  def move_to_head(node)
    remove(node)
    add_to_head(node)
  end

  # Evict the least recently used node if over capacity.
  def evict_if_needed
    return if @map.size < @capacity

    lru = @tail.prev
    remove(lru)
    @map.delete(lru.key)
  end
end