class LRUCache
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
    @size = 0
    @cache = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  def get(key)
    node = @cache[key]
    if node
      move_to_head(node)
      return node.value
    end
    nil
  end

  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      move_to_head(node)
    else
      if @size == @capacity
        evict_least_recently_used
      else
        @size += 1
      end
      node = Node.new(key, value)
      @cache[key] = node
      add_to_head(node)
    end
  end

  private

  def add_to_head(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  def move_to_head(node)
    remove_node(node)
    add_to_head(node)
  end

  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  def evict_least_recently_used
    last = @tail.prev
    remove_node(last)
    @cache.delete(last.key)
  end
end
