# LRU (Least Recently Used) Cache Implementation
#
# This implementation uses a hash map for O(1) lookup and a doubly linked list
# for O(1) insertion, deletion, and reordering of elements based on usage.
# 
# The combination allows for O(1) time complexity for both get and put operations.
class LRUCache
  # Node class for the doubly linked list
  class Node
    attr_accessor :key, :value, :prev, :next
    
    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end
  
  # Initialize the LRU cache with a given capacity
  #
  # @param capacity [Integer] Maximum number of entries the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {} # Hash map for O(1) lookup
    
    # Create dummy head and tail nodes for easier list manipulation
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end
  
  # Get the value associated with the key and mark it as recently used
  #
  # @param key [Object] Key to look up
  # @return [Object, nil] Value if found, nil otherwise
  def get(key)
    node = @cache[key]
    return nil unless node
    
    # Move accessed node to head (mark as recently used)
    move_to_head(node)
    
    node.value
  end
  
  # Insert or update a key-value pair
  #
  # @param key [Object] Key to insert or update
  # @param value [Object] Value to associate with the key
  def put(key, value)
    node = @cache[key]
    
    if node
      # Update existing node
      node.value = value
      move_to_head(node)
    else
      # Create new node
      new_node = Node.new(key, value)
      
      # Check if we need to evict
      if @cache.size >= @capacity
        # Remove the tail node (least recently used)
        tail = remove_tail
        @cache.delete(tail.key)
      end
      
      # Add new node to head
      add_to_head(new_node)
      @cache[key] = new_node
    end
  end
  
  private
  
  # Add node to the head of the doubly linked list
  #
  # @param node [Node] Node to add
  def add_to_head(node)
    node.prev = @head
    node.next = @head.next
    
    @head.next.prev = node
    @head.next = node
  end
  
  # Remove a specific node from the doubly linked list
  #
  # @param node [Node] Node to remove
  def remove_node(node)
    prev_node = node.prev
    next_node = node.next
    
    prev_node.next = next_node
    next_node.prev = prev_node
  end
  
  # Move a node to the head of the doubly linked list
  #
  # @param node [Node] Node to move
  def move_to_head(node)
    remove_node(node)
    add_to_head(node)
  end
  
  # Remove and return the tail node (least recently used)
  #
  # @return [Node] Removed node
  def remove_tail
    last_node = @tail.prev
    remove_node(last_node)
    last_node
  end
end