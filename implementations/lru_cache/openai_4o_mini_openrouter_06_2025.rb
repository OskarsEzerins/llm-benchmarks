class LRUCache
  Node = Struct.new(:key, :value, :prev, :next)

  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value associated with the key if it exists, 
  # and marks the key as the most recently used.
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the head (most recently used)
    remove(node)
    insert(node)
    node.value
  end

  # Inserts or updates the key-value pair in the cache.
  def put(key, value)
    if @cache.key?(key)
      # Update the existing node
      node = @cache[key]
      node.value = value
      remove(node)
      insert(node)
    else
      # Create a new node
      node = Node.new(key, value)
      if @cache.size >= @capacity
        # Evict the least recently used node
        lru_node = @tail.prev
        remove(lru_node)
        @cache.delete(lru_node.key)
      end
      insert(node)
      @cache[key] = node
    end
  end

  private

  # Insert a node right after the head
  def insert(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Remove a node from the linked list
  def remove(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end
end