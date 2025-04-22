# frozen_string_literal: true

# LRUCache implements a Least Recently Used (LRU) caching mechanism with O(1) operations.
# It maintains both a hash map for fast lookups and a doubly linked list for LRU tracking.
#
# Example usage:
#   cache = LRUCache.new(2)
#   cache.put(1, "one")   # Cache is now {1 => "one"}
#   cache.put(2, "two")   # Cache is now {1 => "one", 2 => "two"}
#   cache.get(1)          # Returns "one"
#   cache.put(3, "three") # Evicts key 2, cache is now {1 => "one", 3 => "three"}
class LRUCache
  # Node class for doubly linked list implementation
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  def initialize(capacity)
    raise ArgumentError, "Capacity must be positive" if capacity <= 0

    @capacity = capacity
    @cache = {}
    @head = Node.new  # Dummy head
    @tail = Node.new  # Dummy tail
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value associated with the given key and marks it as most recently used
  # @param key [Object] the key to look up
  # @return [Object, nil] the value associated with the key, or nil if not found
  def get(key)
    return nil unless @cache.key?(key)

    node = @cache[key]
    remove_node(node)
    add_to_front(node)
    node.value
  end

  # Adds or updates a key-value pair in the cache
  # If the cache is at capacity, removes the least recently used item
  # @param key [Object] the key to store
  # @param value [Object] the value to store
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_to_front(node)
    else
      if @cache.size >= @capacity
        # Remove the least recently used item (last item in list)
        lru_node = @tail.prev
        remove_node(lru_node)
        @cache.delete(lru_node.key)
      end

      # Add new node
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_front(new_node)
    end
  end

  # Returns the current size of the cache
  # @return [Integer] number of items in the cache
  def size
    @cache.size
  end

  private

  # Removes a node from the doubly linked list
  # @param node [Node] the node to remove
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Adds a node to the front of the doubly linked list (most recently used)
  # @param node [Node] the node to add to the front
  def add_to_front(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end
end
