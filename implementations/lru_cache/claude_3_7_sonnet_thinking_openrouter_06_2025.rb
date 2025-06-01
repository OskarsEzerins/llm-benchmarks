# LRUCache: A Least Recently Used (LRU) Cache implementation
#
# This class implements an LRU Cache with O(1) time complexity for both
# get and put operations. It uses a combination of a hash map for fast lookups
# and a doubly linked list to track the order of usage.
#
# When the cache reaches its capacity and a new item is added, the least
# recently used item is automatically evicted.
class LRUCache
  # Initialize a new LRU Cache with the specified capacity
  #
  # @param capacity [Integer] The maximum number of items the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {}  # Hash map for O(1) lookups: key -> node
    
    # Initialize dummy head and tail nodes for the doubly linked list
    @head = Node.new(nil, nil)  # Most recently used
    @tail = Node.new(nil, nil)  # Least recently used
    @head.next = @tail
    @tail.prev = @head
  end
  
  # Retrieve a value from the cache by its key
  #
  # @param key The key to look up
  # @return The value associated with the key, or nil if not found
  def get(key)
    if @cache.key?(key)
      # Item exists in cache, move to front (most recently used)
      node = @cache[key]
      # Remove from current position
      remove_node(node)
      # Add to front (most recently used)
      add_to_front(node)
      return node.value
    else
      # Key not found
      return nil
    end
  end
  
  # Insert or update a key-value pair in the cache
  #
  # @param key The key to insert or update
  # @param value The value to associate with the key
  def put(key, value)
    # If key exists, remove the existing node
    if @cache.key?(key)
      remove_node(@cache[key])
    # If at capacity and adding new key, remove least recently used
    elsif @cache.size >= @capacity
      # Remove from cache and linked list
      lru_node = @tail.prev
      remove_node(lru_node)
      @cache.delete(lru_node.key)
    end
    
    # Create new node and add to front
    node = Node.new(key, value)
    add_to_front(node)
    # Add to cache
    @cache[key] = node
  end
  
  private
  
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
  
  # Remove a node from the doubly linked list
  def remove_node(node)
    # Update the adjacent nodes to bypass this node
    node.prev.next = node.next
    node.next.prev = node.prev
  end
  
  # Add a node to the front of the list (most recently used)
  def add_to_front(node)
    # Insert between head and head.next
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end
end