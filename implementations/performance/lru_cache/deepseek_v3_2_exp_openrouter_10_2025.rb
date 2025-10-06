class LRUCache
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initializes the LRU Cache with a maximum capacity
  #
  # @param capacity [Integer] the maximum number of items the cache can hold
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be positive' unless capacity.positive?

    @capacity = capacity
    @cache = {}
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves a value from the cache by key
  #
  # @param key [Object] the key to look up
  # @return [Object, nil] the value associated with the key, or nil if not found
  def get(key)
    node = @cache[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Inserts or updates a key-value pair in the cache
  #
  # @param key [Object] the key to insert or update
  # @param value [Object] the value to associate with the key
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
        lru = pop_tail
        @cache.delete(lru.key)
      end
    end
  end

  private

  # Adds a node right after the head
  def add_node(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Removes a node from the linked list
  def remove_node(node)
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
  end

  # Moves a node to the head (most recently used position)
  def move_to_head(node)
    remove_node(node)
    add_node(node)
  end

  # Removes and returns the tail node (least recently used)
  def pop_tail
    lru = @tail.prev
    remove_node(lru)
    lru
  end
end