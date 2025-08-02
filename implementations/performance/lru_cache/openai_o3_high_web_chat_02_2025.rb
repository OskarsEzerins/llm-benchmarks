class LRUCache
  # A node in the doubly-linked list used to track usage order.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initializes the LRUCache with a fixed capacity.
  #
  # The cache uses a hash for O(1) lookups and a doubly-linked list to maintain
  # the order of usage. The most recently used node is right after the head,
  # and the least recently used node is just before the tail.
  #
  # @param capacity [Integer] The maximum number of key-value pairs the cache can hold.
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value for the given key, marking it as most recently used.
  #
  # If the key exists, the associated node is moved to the head of the list.
  # If the key is not found, nil is returned.
  #
  # @param key [Object] The key to look up.
  # @return [Object, nil] The value associated with the key, or nil if not found.
  def get(key)
    node = @cache[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Inserts a key-value pair into the cache or updates an existing key.
  #
  # If the key already exists, its value is updated and the node is moved to the head.
  # If the key does not exist, a new node is created. If adding the new node exceeds
  # the cache's capacity, the least recently used node (at the tail) is removed.
  #
  # @param key [Object] The key to insert or update.
  # @param value [Object] The value to associate with the key.
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      move_to_head(node)
    else
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_node(new_node)

      if @cache.size > @capacity
        lru = pop_tail
        @cache.delete(lru.key)
      end
    end
  end

  private

  # Adds a node right after the head, marking it as most recently used.
  #
  # @param node [Node] The node to add.
  def add_node(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Removes a node from the doubly-linked list.
  #
  # @param node [Node] The node to remove.
  def remove_node(node)
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
  end

  # Moves a node to the head, marking it as most recently used.
  #
  # @param node [Node] The node to move.
  def move_to_head(node)
    remove_node(node)
    add_node(node)
  end

  # Removes and returns the least recently used node from the tail.
  #
  # @return [Node] The removed node.
  def pop_tail
    node = @tail.prev
    remove_node(node)
    node
  end
end
