# Implements an LRU (Least Recently Used) Cache with O(1) get and put operations
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

  # Initialize the LRU cache with a specified capacity
  #
  # @param capacity [Integer] Maximum number of items the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {} # Hash map for O(1) access to nodes
    
    # Dummy head and tail nodes for the doubly linked list
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve item from cache by key
  # Moves accessed item to the front (most recently used position)
  #
  # @param key [Object] Key to look up
  # @return [Object, nil] Value associated with key or nil if not found
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move node to front (mark as most recently used)
    remove_node(node)
    add_to_front(node)

    node.value
  end

  # Insert or update a key-value pair in the cache
  # If cache is at capacity, removes the least recently used item
  #
  # @param key [Object] Key to insert or update
  # @param value [Object] Value to associate with the key
  def put(key, value)
    if @cache.key?(key)
      # Update existing key
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_to_front(node)
    else
      # Insert new key
      if @cache.size >= @capacity
        # Remove least recently used item (tail's previous node)
        lru_node = @tail.prev
        remove_node(lru_node)
        @cache.delete(lru_node.key)
      end

      # Add new node to front
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_front(new_node)
    end
  end

  private

  # Add a node to the front of the linked list (right after head)
  #
  # @param node [Node] Node to add
  def add_to_front(node)
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end

  # Remove a node from the linked list
  #
  # @param node [Node] Node to remove
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end
end