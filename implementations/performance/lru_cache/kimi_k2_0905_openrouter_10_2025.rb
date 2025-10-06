# LRUCache: a fixed-capacity key-value store evicting the least recently used item
#   when full. Both get and put run in O(1) time.
#
# Usage
#   cache = LRUCache.new(5)
#   cache.put(:a, 1)          # => true
#   cache.get(:a)             # => 1
#   cache.get(:missing)       # => nil
#
class LRUCache
  # Node of an intrusive doubly-linked list
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key   = key
      @value = value
      @prev  = nil
      @next  = nil
    end
  end

  # Sentinel head/tail for an intrusive doubly-linked list
  class List
    def initialize
      @head = Node.new(nil, nil)
      @tail = Node.new(nil, nil)
      @head.next = @tail
      @tail.prev = @head
    end

    # insert after sentinel head (MRU)
    def push_front(node)
      node.prev = @head
      node.next = @head.next
      @head.next.prev = node
      @head.next      = node
    end

    # detach node from wherever it is
    def unlink(node)
      node.prev.next = node.next
      node.next.prev = node.prev
    end

    # detach and return node before sentinel tail (LRU)
    def pop_back
      node = @tail.prev
      return nil if node == @head
      unlink(node)
      node
    end

    # move existing node to the front (MRU)
    def move_to_front(node)
      unlink(node)
      push_front(node)
    end
  end

  # -------------------- public API --------------------

  # capacity – positive integer
  def initialize(capacity)
    raise ArgumentError, 'capacity must be > 0' unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @map   = {}          # key => Node
    @list  = List.new
  end

  # Return value for key (nil if absent) and promote to MRU
  def get(key)
    node = @map[key]
    return nil unless node

    @list.move_to_front(node)
    node.value
  end

  # Insert or update key with value. Evict LRU if needed.
  def put(key, value)
    if @map.key?(key)
      node = @map[key]
      node.value = value
      @list.move_to_front(node)
    else
      node = Node.new(key, value)
      @map[key] = node
      @list.push_front(node)

      if @map.size > @capacity
        lru = @list.pop_back
        @map.delete(lru.key)
      end
    end
    true
  end
end