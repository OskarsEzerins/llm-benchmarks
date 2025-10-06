class LRUCache
  # Initialize the LRU Cache with a maximum capacity
  #
  # @param capacity [Integer] the maximum number of items the cache can hold
  def initialize(capacity)
    raise ArgumentError, "Capacity must be positive" unless capacity.positive?
    
    @capacity = capacity
    @cache = {}  # Hash for O(1) key-value lookups
    @head = Node.new(nil, nil)  # Dummy head
    @tail = Node.new(nil, nil)  # Dummy tail
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve value by key and mark as most recently used
  #
  # @param key [Object] the key to look up
  # @return [Object, nil] the value associated with key, or nil if not found
  def get(key)
    node = @cache[key]
    return nil unless node
    
    # Move to head (most recently used)
    remove_node(node)
    add_to_head(node)
    node.value
  end

  # Insert or update a key-value pair
  #
  # @param key [Object] the key to insert/update
  # @param value [Object] the value to associate with the key
  def put(key, value)
    if @cache.key?(key)
      # Update existing node
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_to_head(node)
    else
      # Create new node
      node = Node.new(key, value)
      @cache[key] = node
      add_to_head(node)
      
      # Evict least recently used if over capacity
      if @cache.size > @capacity
        lru = @tail.prev
        remove_node(lru)
        @cache.delete(lru.key)
      end
    end
  end

  private

  # Doubly linked list node for tracking access order
  class Node
    attr_accessor :key, :value, :prev, :next
    
    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Remove a node from the linked list
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Add a node to the head (most recently used position)
  def add_to_head(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end
end