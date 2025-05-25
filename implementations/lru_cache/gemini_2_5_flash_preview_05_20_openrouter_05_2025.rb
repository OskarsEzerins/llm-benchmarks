# Implements a Least Recently Used (LRU) Cache.
#
# The LRUCache stores key-value pairs with a fixed maximum capacity.
# When the cache capacity is exceeded, the least recently used item is
# automatically evicted to make space for new items.
#
# It aims for O(1) time complexity for both `get` and `put` operations
# by using a hash map for quick lookups and a doubly linked list
# to maintain the order of recently used items.
#
# Usage:
#   cache = LRUCache.new(capacity)
#   cache.put(key, value)
#   value = cache.get(key)
class LRUCache
  # Represents a node in the doubly linked list used to track
  # the recency of items in the LRU cache.
  # Each node holds a key and a value, and references to the
  # previous and next nodes in the list.
  Node = Struct.new(:key, :value, :prev, :next)

  # Initializes a new LRUCache with the specified maximum capacity.
  #
  # @param capacity [Integer] The maximum number of key-value pairs the cache can hold.
  # @raise [ArgumentError] if capacity is not a positive integer.
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @cache = {} # Hash map to store key -> Node mappings for O(1) lookups
    @head = nil # Head of the doubly linked list (most recently used)
    @tail = nil # Tail of the doubly linked list (least recently used)
    @size = 0   # Current number of items in the cache
  end

  # Retrieves the value associated with the given key.
  # If the key is found, it marks the key as most recently used.
  #
  # @param key [Object] The key to look up.
  # @return [Object, nil] The value associated with the key, or nil if the key is not found.
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the head of the list (most recently used)
    move_to_head(node)
    node.value
  end

  # Inserts a new key-value pair into the cache or updates an existing key's value.
  # If inserting a new key causes the cache to exceed its capacity, the least
  # recently used item is automatically evicted.
  #
  # @param key [Object] The key to insert or update.
  # @param value [Object] The value to associate with the key.
  def put(key, value)
    node = @cache[key]

    if node
      # Key already exists, update its value and move to head
      node.value = value
      move_to_head(node)
    else
      # New key
      if @size >= @capacity
        # Cache is full, evict the least recently used item (tail)
        evict_lru
      end

      # Create a new node and add it to the cache and head of the list
      new_node = Node.new(key, value, nil, @head)
      if @head
        @head.prev = new_node
      end
      @head = new_node
      @tail ||= new_node # If cache was empty, new_node is also the tail

      @cache[key] = new_node
      @size += 1
    end
  end

  private

  # Moves a given node to the head of the doubly linked list.
  # This signifies that the node has just been accessed and is now
  # the most recently used item.
  #
  # @param node [Node] The node to move.
  def move_to_head(node)
    return if node == @head # Already the most recently used

    # Detach node from its current position
    if node == @tail
      @tail = node.prev
      @tail.next = nil if @tail
    else
      node.prev.next = node.next
      node.next.prev = node.prev
    end

    # Attach node to the head
    node.next = @head
    node.prev = nil
    @head.prev = node
    @head = node
  end

  # Evicts the least recently used item from the cache.
  # This item is always at the tail of the doubly linked list.
  def evict_lru
    return unless @tail # Nothing to evict if cache is empty

    # Remove from hash map
    @cache.delete(@tail.key)

    # Remove from linked list
    if @tail.prev
      @tail.prev.next = nil
      @tail = @tail.prev
    else
      # Cache becomes empty after eviction
      @head = nil
      @tail = nil
    end

    @size -= 1
  end
end