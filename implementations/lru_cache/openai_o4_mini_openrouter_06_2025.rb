class LRUCache
  # LRUCache implements a Least-Recently-Used cache with O(1) get and put operations.
  # Uses a hash map and a doubly linked list to track usage.
  #
  # Example:
  #   cache = LRUCache.new(2)
  #   cache.put(1, 'a')
  #   cache.put(2, 'b')
  #   cache.get(1)       # => 'a'
  #   cache.put(3, 'c')  # evicts key 2
  #   cache.get(2)       # => nil

  def initialize(capacity)
    raise ArgumentError, 'Capacity must be positive' unless capacity.positive?
    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Public: Retrieve value for key and mark as most recently used.
  # Returns the value or nil if not found.
  def get(key)
    node = @cache[key]
    return nil unless node
    move_to_front(node)
    node.value
  end

  # Public: Insert or update key with value.
  # If capacity exceeded, evicts least recently used entry.
  def put(key, value)
    if (node = @cache[key])
      node.value = value
      move_to_front(node)
    else
      if @cache.size >= @capacity
        lru = @tail.prev
        remove_node(lru)
        @cache.delete(lru.key)
      end
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_front(new_node)
    end
    nil
  end

  private

  def move_to_front(node)
    remove_node(node)
    add_to_front(node)
  end

  def remove_node(node)
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
  end

  def add_to_front(node)
    first = @head.next
    @head.next = node
    node.prev = @head
    node.next = first
    first.prev = node
  end

  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end
end