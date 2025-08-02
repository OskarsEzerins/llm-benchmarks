# Implements a Least Recently Used (LRU) cache.
#
# The cache has a fixed capacity and evicts the least recently used entries
# when it reaches capacity.
#
# Usage:
#   cache = LRUCache.new(capacity)
#   cache.put(key, value)
#   value = cache.get(key)
#
# The LRU mechanism works by maintaining a doubly-linked list of nodes,
# where each node represents a key-value pair in the cache. When a key-value
# pair is accessed (via get or put), it's moved to the head of the list,
# marking it as the most recently used. When the cache reaches its capacity,
# the node at the tail of the list (the least recently used) is evicted.
# A hash map is used for quick access to the nodes by key.
class LRUCache
  # Node structure for the doubly-linked list
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  def initialize(capacity)
    @capacity = capacity
    @map = {}
    @head = nil
    @tail = nil
  end

  def get(key)
    node = @map[key]
    return nil if node.nil?

    remove_node(node)
    add_node_to_head(node)

    node.value
  end

  def put(key, value)
    node = @map[key]

    if node
      node.value = value
      remove_node(node)
      add_node_to_head(node)
    else
      node = Node.new(key, value)
      @map[key] = node
      add_node_to_head(node)

      if @map.size > @capacity
        remove_tail_node
      end
    end
  end

  private

  def add_node_to_head(node)
    if @head.nil?
      @head = node
      @tail = node
    else
      node.next = @head
      @head.prev = node
      @head = node
    end
  end

  def remove_node(node)
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

  def remove_tail_node
    return if @tail.nil?

    @map.delete(@tail.key)
    if @tail.prev
      @tail.prev.next = nil
      @tail = @tail.prev
    else
      @head = nil
      @tail = nil
    end
  end
end
