class LRUCache
  class Node
    attr_accessor :key, :value, :prev_node, :next_node

    def initialize(key, value)
      @key = key
      @value = value
      @prev_node = nil
      @next_node = nil
    end
  end

  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.positive?

    @capacity = capacity
    @hash = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next_node = @tail
    @tail.prev_node = @head
  end

  def get(key)
    node = @hash[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  def put(key, value)
    if @hash.key?(key)
      node = @hash[key]
      node.value = value
      move_to_head(node)
    else
      node = Node.new(key, value)
      @hash[key] = node
      add_node(node)
      evict if @hash.size > @capacity
    end
  end

  private

  def add_node(node)
    node.prev_node = @head
    node.next_node = @head.next_node
    @head.next_node.prev_node = node
    @head.next_node = node
  end

  def remove_node(node)
    node.prev_node.next_node = node.next_node
    node.next_node.prev_node = node.prev_node
  end

  def move_to_head(node)
    remove_node(node)
    add_node(node)
  end

  def evict
    evicted = pop_tail
    @hash.delete(evicted.key)
  end

  def pop_tail
    node = @tail.prev_node
    remove_node(node)
    node
  end
end
