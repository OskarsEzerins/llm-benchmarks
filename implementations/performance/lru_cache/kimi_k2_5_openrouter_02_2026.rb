class LRUCache
  # Node represents an entry in the doubly linked list
  Node = Struct.new(:key, :value, :prev, :next)
  
  # Initializes the LRU Cache with the specified capacity.
  # Uses a hash map for O(1) key lookup and a doubly linked list 
  # to maintain usage order (head = most recent, tail = least recent).
  # @param capacity [Integer] the maximum number of items the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    
    # Dummy head and tail nodes eliminate edge cases for list operations
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end
  
  # Retrieves the value associated with the key.
  # If found, marks the entry as most recently used.
  # Time Complexity: O(1)
  # @param key the key to look up
  # @return [Object] the value associated with the key, or nil if not found
  def get(key)
    node = @cache[key]
    return nil unless node
    
    move_to_head(node)
    node.value
  end
  
  # Inserts or updates a key-value pair.
  # If the key exists, updates the value and marks as most recently used.
  # If inserting a new key exceeds capacity, evicts the least recently used 
  # item (at tail) before insertion.
  # Time Complexity: O(1)
  # @param key the key to insert or update
  # @param value the value to associate with the key
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      move_to_head(node)
    else
      node = Node.new(key, value)
      @cache[key] = node
      add_to_head(node)
      
      if @cache.size > @capacity
        lru = remove_tail
        @cache.delete(lru.key)
      end
    end
  end
  
  private
  
  # Adds node directly after the head (most recent position)
  def add_to_head(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end
  
  # Removes node from its current position in the list
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end
  
  # Moves existing node to the most recent position (after head)
  def move_to_head(node)
    remove_node(node)
    add_to_head(node)
  end
  
  # Removes and returns the node at the tail (least recent)
  def remove_tail
    node = @tail.prev
    remove_node(node)
    node
  end
end