# LRUCache implements a Least Recently Used (LRU) cache with O(1) get and put operations.
#
# Usage:
#   cache = LRUCache.new(capacity)
#   cache.put(key, value) # Inserts or updates a key-value pair, evicts LRU if over capacity.
#   value = cache.get(key) # Returns value for key if present, else nil. Marks key as most recently used.
#
# LRU Mechanism:
#   - Each access (get or put) moves the key to the "most recently used" position.
#   - When capacity is exceeded, the "least recently used" key is evicted.
#
# Implementation details:
#   - Uses a Hash for O(1) lookups.
#   - Uses a doubly-linked list for O(1) insertions/deletions and tracking usage order.
#
class LRUCache
  # Internal class representing a node in the double-linked list.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize the LRUCache with a positive integer capacity.
  #
  # @param capacity [Integer] the maximum number of entries in the cache
  # @raise [ArgumentError] if capacity < 1
  def initialize(capacity)
    raise ArgumentError, "Capacity must be positive" unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @map = {} # key => node
    # Dummy head (LRU, oldest) and tail (MRU, newest) sentinels
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Get the value for the given key, or nil if not present.
  # Marks the key as recently used if found.
  #
  # @param key [Object] The key to lookup.
  # @return [Object, nil] The associated value, or nil if not found.
  def get(key)
    node = @map[key]
    return nil unless node

    move_to_tail(node)
    node.value
  end

  # Insert or update a key-value pair.
  # If the cache exceeds its capacity, evicts the least recently used key.
  #
  # @param key [Object] The key to insert/update.
  # @param value [Object] The value to associate.
  # @return [void]
  def put(key, value)
    if (node = @map[key])
      node.value = value
      move_to_tail(node)
    else
      node = Node.new(key, value)
      @map[key] = node
      add_to_tail(node)
      if @map.size > @capacity
        evict_lru!
      end
    end
    nil
  end

  private

  # Move a node to the tail (mark as most recently used).
  def move_to_tail(node)
    remove_node(node)
    add_to_tail(node)
  end

  # Remove a node from the linked list.
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
    node.prev = nil
    node.next = nil
  end

  # Add a node just before the tail (most recently used).
  def add_to_tail(node)
    last = @tail.prev
    last.next = node
    node.prev = last
    node.next = @tail
    @tail.prev = node
  end

  # Evict the least recently used node (head.next).
  def evict_lru!
    lru = @head.next
    remove_node(lru)
    @map.delete(lru.key)
  end
end