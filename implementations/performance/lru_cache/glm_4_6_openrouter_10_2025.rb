# LRUCache - A simple fixed-size Least Recently Used (LRU) cache.
#
# The cache stores a limited number of key-value pairs. When the capacity
# is exceeded, the least recently accessed entry is evicted.
#
# @example Basic usage
#   cache = LRUCache.new(3)
#   cache.put(:a, 1)
#   cache.put(:b, 2)
#   cache.get(:a) #=> 1 (now :a is most recent)
#   cache.put(:c, 3)
#   cache.put(:d, 4) # :b is evicted because it was least recently used
#
# The implementation uses a hash for O(1) lookup and a doubly‑linked list
# to maintain the order of usage, guaranteeing O(1) time for both +get+ and
# +put+ operations.
class LRUCache
  # Internal node used by the doubly linked list.
  #
  # @attr key [Object] the cache key
  # @attr value [Object] the stored value
  # @attr prev [Node, nil] previous node in the list
  # @attr next [Node, nil] next node in the list
  Node = Struct.new(:key, :value, :prev, :next)

  # Creates a new LRU cache with the given maximum capacity.
  #
  # @param capacity [Integer] the maximum number of entries the cache can hold
  # @raise [ArgumentError] if +capacity+ is not a positive integer
  def initialize(capacity)
    unless capacity.is_a?(Integer) && capacity > 0
      raise ArgumentError, 'Capacity must be a positive integer'
    end

    @capacity = capacity
    @store = {} # key => Node
    # Sentinel nodes to avoid edge‑case checks
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value associated with +key+ and marks the entry as most
  # recently used.
  #
  # @param key [Object] the key to look up
  # @return [Object, nil] the stored value, or +nil+ if the key is absent
  def get(key)
    node = @store[key]
    return nil unless node

    move_to_front(node)
    node.value
  end

  # Inserts or updates a key-value pair. If a new key would cause the cache
  # to exceed its capacity, the least recently used entry is evicted.
  #
  # @param key [Object] the key to store
  # @param value [Object] the value to associate with +key+
  # @return [void]
  def put(key, value)
    node = @store[key]

    if node
      node.value = value
      move_to_front(node)
    else
      new_node = Node.new(key, value)
      @store[key] = new_node
      add_to_front(new_node)

      evict if @store.size > @capacity
    end
  end

  private

  # Moves +node+ to the front (most‑recent position) of the list.
  #
  # @param node [Node] the node to move
  # @return [void]
  def move_to_front(node)
    remove(node)
    add_to_front(node)
  end

  # Removes +node+ from its current position in the linked list.
  #
  # @param node [Node] the node to remove
  # @return [void]
  def remove(node)
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
  end

  # Inserts +node+ right after the head sentinel.
  #
  # @param node [Node] the node to insert
  # @return [void]
  def add_to_front(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Evicts the least recently used entry (the node before the tail sentinel).
  #
  # @return [void]
  def evict
    lru = @tail.prev
    remove(lru)
    @store.delete(lru.key)
  end
end