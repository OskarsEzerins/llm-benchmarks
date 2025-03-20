# LRUCache implements a Least Recently Used (LRU) cache with O(1) get and put operations.
# It uses a doubly linked list (with dummy head and tail nodes) to track usage order and a hash for fast lookups.
#
# Usage:
#   cache = LRUCache.new(capacity)
#   cache.put(key, value)    # Inserts or updates a key-value pair
#   value = cache.get(key)   # Retrieves the value for key (returns nil if not found) and marks it as recently used
#
# When a new key is added and the cache exceeds its capacity, the least recently used key is automatically evicted.
class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil) # dummy head
    @tail = Node.new(nil, nil) # dummy tail
    @head.next = @tail
    @tail.prev = @head
  end

  def get(key)
    node = @cache[key]
    return nil unless node
    move_to_head(node)
    node.value
  end

  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      move_to_head(node)
    else
      node = Node.new(key, value)
      @cache[key] = node
      add_node(node)
      if @cache.size > @capacity
        tail_node = pop_tail
        @cache.delete(tail_node.key)
      end
    end
  end

  private

  class Node
    attr_accessor :key, :value, :prev, :next
    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  def add_node(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  def move_to_head(node)
    remove_node(node)
    add_node(node)
  end

  def pop_tail
    node = @tail.prev
    remove_node(node)
    node
  end
end
