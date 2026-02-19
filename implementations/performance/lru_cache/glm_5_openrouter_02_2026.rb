class LRUCache
  # Internal Node class for the Doubly Linked List.
  # Each node stores a key, value, and pointers to previous/next nodes.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initializes a new LRU Cache.
  #
  # @param capacity [Integer] The maximum number of items the cache can hold.
  def initialize(capacity)
    @capacity = capacity
    @cache = {} # Hash map for O(1) lookups: key => Node

    # Dummy head and tail nodes to simplify boundary logic (sentinels).
    # Head represents the Most Recently Used (MRU) end.
    # Tail represents the Least Recently Used (LRU) end.
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value for the given key.
  # If the key exists, the corresponding node is moved to the head (MRU position).
  #
  # @param key [Object] The key to look up.
  # @return [Object, nil] The value associated with the key, or nil if not found.
  def get(key)
    node = @cache[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Inserts or updates a key-value pair.
  # If the key exists, updates the value and moves the node to the head.
  # If the key is new, creates a new node, adds it to the head, and checks capacity.
  # If capacity is exceeded, the node at the tail (LRU) is evicted.
  #
  # @param key [Object] The key to insert or update.
  # @param value [Object] The value to store.
  # @return [void]
  def put(key, value)
    node = @cache[key]

    if node
      # Update existing node
      node.value = value
      move_to_head(node)
    else
      # Add new node
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_node(new_node)

      # Evict LRU if capacity exceeded
      evict_lru if @cache.size > @capacity
    end
  end

  private

  # Adds a node right after the dummy head.
  # @param node [Node] The node to add.
  def add_node(node)
    node.prev = @head
    node.next = @head.next

    @head.next.prev = node
    @head.next = node
  end

  # Removes a node from the linked list.
  # @param node [Node] The node to remove.
  def remove_node(node)
    prev_node = node.prev
    next_node = node.next

    prev_node.next = next_node
    next_node.prev = prev_node
  end

  # Moves an existing node to the head (MRU position).
  # @param node [Node] The node to move.
  def move_to_head(node)
    remove_node(node)
    add_node(node)
  end

  # Evicts the least recently used node (the one before the dummy tail).
  def evict_lru
    lru_node = @tail.prev
    remove_node(lru_node)
    @cache.delete(lru_node.key)
  end
end