# LRUCache - A Least Recently Used Cache implementation
#
# The LRUCache provides O(1) time complexity for both get and put operations.
# It automatically evicts the least recently used items when the capacity is exceeded.
#
# Usage:
#   cache = LRUCache.new(capacity)
#   cache.put(key, value)  # Adds or updates a key-value pair
#   cache.get(key)         # Retrieves a value by key, returns nil if not found
class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new
    @tail = Node.new
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value for the given key if it exists in the cache
  # Updates the key to be the most recently used if found
  # Returns nil if the key is not in the cache
  # Time complexity: O(1)
  def get(key)
    return nil unless @cache.key?(key)

    node = @cache[key]
    remove_node(node)
    add_to_front(node)
    node.value
  end

  # Adds or updates a key-value pair in the cache
  # If the key already exists, updates its value and marks it as most recently used
  # If the key is new and the cache is at capacity, removes the least recently used item
  # Time complexity: O(1)
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_to_front(node)
    else
      if @cache.size >= @capacity
        remove_least_recently_used
      end

      node = Node.new(key, value)
      @cache[key] = node
      add_to_front(node)
    end
  end

  private

  # Internal node class for the doubly linked list
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Removes a node from the doubly linked list
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Adds a node to the front of the doubly linked list (most recently used)
  def add_to_front(node)
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end

  # Removes the least recently used item (from the end of the list)
  def remove_least_recently_used
    lru_node = @tail.prev
    remove_node(lru_node)
    @cache.delete(lru_node.key)
  end
end
