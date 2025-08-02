# LRUCache implements a Least Recently Used cache using
# a Hash for O(1) lookups and a doubly linked list for
# O(1) insertion and eviction of the least recently used item.
#
# Usage example:
#   cache = LRUCache.new(3)
#   cache.put(:a, 100)
#   cache.put(:b, 200)
#   cache.get(:a)       # => 100 (becomes most recently used)
#   cache.put(:c, 300)
#   cache.put(:d, 400)  # evicts :b (least recently used at this point)
#   cache.get(:b)       # => nil
class LRUCache
  Node = Struct.new(:key, :value, :prev, :nxt)

  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.nxt = @tail
    @tail.prev = @head
  end

  def get(key)
    node = @cache[key]
    return nil unless node
    move_to_head(node)
    node.value
  end

  def put(key, value)
    node = @cache[key]
    if node
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

  def add_node(node)
    node.prev = @head
    node.nxt = @head.nxt
    @head.nxt.prev = node
    @head.nxt = node
  end

  def remove_node(node)
    node.prev.nxt = node.nxt
    node.nxt.prev = node.prev
  end

  def move_to_head(node)
    remove_node(node)
    add_node(node)
  end

  def pop_tail
    real_tail = @tail.prev
    remove_node(real_tail)
    real_tail
  end
end
