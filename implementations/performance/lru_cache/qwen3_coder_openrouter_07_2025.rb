# LRU Cache implementation using a hash map and doubly linked list
# for O(1) get and put operations.
class LRUCache
  # Node class for the doubly linked list
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize the LRU cache with a given capacity
  # @param capacity [Integer] the maximum number of entries the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {} # Hash map for O(1) access to nodes

    # Dummy head and tail nodes for the doubly linked list
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Get the value for a given key and mark it as most recently used
  # @param key [Object] the key to look up
  # @return [Object, nil] the value associated with the key, or nil if not found
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the head (most recently used)
    move_to_head(node)
    node.value
  end

  # Insert or update a key-value pair in the cache
  # @param key [Object] the key to insert or update
  #param value [Object] the value to associate with the key
  def put(key, value)
    node = @cache[key]

    if node
      # Update existing node
      node.value = value
      move_to_head(node)
    else
      # Insert new node
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_head(new_node)

      # Evict the least recently used item if cache is at capacity
      if @cache.size > @capacity
        tail_node = remove_tail
        @cache.delete(tail_node.key)
      end
    end
  end

  private

  # Add a node to the head of the doubly linked list
  # @param node [Node] the node to add
  def add_to_head(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Remove a node from the doubly linked list
  # @param node [Node] the node to remove
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Move a node to the head of the doubly linked list
  # @param node [Node] the node to move
  def move_to_head(node)
    remove_node(node)
    add_to_head(node)
  end

  # Remove the tail node (least recently used) and return it
  # @return [Node] the removed node
  def remove_tail
    last_node = @tail.prev
    remove_node(last_node)
    last_node
  end
end