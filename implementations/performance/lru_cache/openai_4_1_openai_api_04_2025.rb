# LRUCache: A fixed-capacity Least Recently Used (LRU) cache.
#
# Usage:
#   cache = LRUCache.new(100)        # Initialize with maximum capacity of 100
#   cache.put(:foo, 42)              # Add key :foo with value 42
#   val = cache.get(:foo)            # Returns 42, marks :foo as most recently used
#   cache.put(:bar, 99)              # Add key :bar
#   cache.get(:baz)                  # Returns nil (not present)
#
# LRU Mechanism:
#   Every cache access (get/put) updates usage order.
#   When cache exceeds capacity, least recently used key is evicted.
#
# Notes:
#   - All operations are O(1) time complexity.
#   - Only Ruby's standard library is used.
#
class LRUCache
  # Node for doubly-linked list
  Node = Struct.new(:key, :value, :prev, :next)

  # Create a new LRUCache
  #
  # @param capacity [Integer] Maximum number of entries in the cache (must be > 0)
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @map = {} # { key => Node }
    # Sentinel head/tail nodes to simplify list operations
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Get value for key and mark as most recently used.
  #
  # @param key [Object] The key to look up.
  # @return [Object, nil] Returns associated value or nil if not found.
  def get(key)
    node = @map[key]
    return nil unless node

    _move_to_head(node)
    node.value
  end

  # Insert or update a key-value pair.
  #
  # Updates recentness and evicts least recently used key if at capacity.
  #
  # @param key [Object]
  # @param value [Object]
  # @return [void]
  def put(key, value)
    node = @map[key]
    if node
      node.value = value
      _move_to_head(node)
    else
      node = Node.new(key, value)
      @map[key] = node
      _add_after_head(node)
      if @map.size > @capacity
        _evict_lru
      end
    end
    nil
  end

  private

  # Remove a node from the linked list.
  def _remove(node)
    prev = node.prev
    nex  = node.next
    prev.next = nex
    nex.prev = prev
    node.prev = node.next = nil
    nil
  end

  # Add a node right after head (most recently used position).
  def _add_after_head(node)
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
    nil
  end

  # Move a node to most recently used position.
  def _move_to_head(node)
    _remove(node)
    _add_after_head(node)
    nil
  end

  # Remove the least recently used node from the cache and linked list.
  def _evict_lru
    lru = @tail.prev
    _remove(lru)
    @map.delete(lru.key)
    nil
  end
end
