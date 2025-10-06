# An LRU (Least Recently Used) cache implementation.
#
# The cache has a fixed capacity and maintains the order of use.
# When the cache is full and a new key is inserted, the least recently used
# key is evicted.
#
# = Example
#
#   cache = LRUCache.new(2)
#   cache.put(1, 'one')
#   cache.put(2, 'two')
#   cache.get(1)  #=> "one"
#   cache.put(3, 'three') # evicts key 2
#   cache.get(2)  #=> nil
#
class LRUCache
  def initialize(capacity)
    raise ArgumentError, 'capacity must be positive' if capacity <= 0

    @capacity = capacity
    @table = {} # key => node
    @head = nil # most recently used
    @tail = nil # least recently used
  end

  # Retrieves the value associated with +key+ if present.
  # Marks the key as most recently used.
  #
  # Returns the value or +nil+ if the key is not found.
  def get(key)
    node = @table[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Inserts or updates the key-value pair.
  # If the key is new and the cache is at capacity,
  # the least recently used key is evicted.
  #
  # Returns +self+ for chaining.
  def put(key, value)
    if @table[key]
      node = @table[key]
      node.value = value
      move_to_head(node)
    else
      node = Node.new(key, value)
      @table[key] = node
      prepend(node)
      evict_lru if @table.size > @capacity
    end
    self
  end

  private

  Node = Struct.new(:key, :value, :prev, :next)

  def prepend(node)
    node.prev = nil
    node.next = @head
    @head.prev = node if @head
    @head = node
    @tail = node unless @tail
  end

  def remove(node)
    if node.prev
      node.prev.next = node.next
    else
      @head = node.next
    end

    if node.next
      node.next.prev = node.prev
    else
      @tail = node.prev
    end
  end

  def move_to_head(node)
    return if node.equal?(@head)

    remove(node)
    prepend(node)
  end

  def evict_lru
    lru = @tail
    remove(lru)
    @table.delete(lru.key)
  end
end