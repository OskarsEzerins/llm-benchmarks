# LRUCache implements a fixed-size cache with LRU eviction.
#
# Example:
#   cache = LRUCache.new(5)
#   cache.put('a', 1)
#   cache.get('a') # => 1
#   cache.get('b') # => nil
#
# The cache uses a hash map and a doubly linked list to achieve O(1) time
# for get and put operations. The most recently used entries are moved to
# the front of the list; when capacity is exceeded, the least recently used
# entry (at the end of the list) is removed.
class LRUCache
  Node = Struct.new(:key, :value, :prev, :next)

  # @param capacity [Integer] maximum number of entries
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve value for key and mark as most recently used.
  # @param key [Object]
  # @return [Object, nil]
  def get(key)
    node = @cache[key]
    return unless node

    remove_node(node)
    add_to_head(node)
    node.value
  end

  # Insert or update key-value. Evict least recently used if needed.
  # @param key [Object]
  # @param value [Object]
  # @return [void]
  def put(key, value)
    if (node = @cache[key])
      node.value = value
      remove_node(node)
      add_to_head(node)
    else
      node = Node.new(key, value)
      @cache[key] = node
      add_to_head(node)
      if @cache.size > @capacity
        lru = @tail.prev
        remove_node(lru)
        @cache.delete(lru.key)
      end
    end
  end

  private

  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  def add_to_head(node)
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end
end
