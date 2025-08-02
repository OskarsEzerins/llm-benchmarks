# LRUCache implements a Least Recently Used (LRU) cache with O(1) time complexity
# for both get and put operations.
#
# The cache has a fixed capacity and automatically evicts the least recently used
# items when the capacity is exceeded.
#
# Example usage:
#   cache = LRUCache.new(3)
#   cache.put("key1", "value1")
#   cache.put("key2", "value2")
#   cache.put("key3", "value3")
#   cache.get("key1")  # returns "value1" and marks "key1" as most recently used
#   cache.put("key4", "value4")  # evicts "key2" as it's the least recently used
#   cache.get("key2")  # returns nil as "key2" was evicted
class LRUCache
  # Initializes a new LRU cache with the specified capacity.
  #
  # @param capacity [Integer] The maximum number of items the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil)  # Dummy head
    @tail = Node.new(nil, nil)  # Dummy tail
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves a value from the cache by its key and marks it as most recently used.
  #
  # @param key The key to look up
  # @return The value associated with the key, or nil if the key is not found
  def get(key)
    return nil unless @cache.key?(key)
    
    node = @cache[key]
    remove_node(node)
    add_to_head(node)
    node.value
  end

  # Inserts or updates a key-value pair in the cache.
  # If the key already exists, updates its value and marks it as most recently used.
  # If the key is new and the cache is at capacity, evicts the least recently used item.
  #
  # @param key The key to insert or update
  # @param value The value to associate with the key
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_to_head(node)
    else
      node = Node.new(key, value)
      @cache[key] = node
      add_to_head(node)
      
      if @cache.size > @capacity
        # Remove the least recently used item (the one before tail)
        lru = @tail.prev
        remove_node(lru)
        @cache.delete(lru.key)
      end
    end
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

  # Removes a node from the linked list
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Adds a node to the head of the linked list (most recently used)
  def add_to_head(node)
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end
end