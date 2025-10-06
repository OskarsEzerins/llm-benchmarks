# frozen_string_literal: true

##
# LRUCache implements a Least Recently Used (LRU) cache with O(1) time complexity
# for both get and put operations.
#
# The cache maintains a maximum capacity, and when that capacity is exceeded,
# the least recently used item is automatically evicted.
#
# Usage:
#   cache = LRUCache.new(2)
#   cache.put(1, 1)
#   cache.put(2, 2)
#   cache.get(1)    # => 1
#   cache.put(3, 3) # evicts key 2
#   cache.get(2)    # => nil
#
class LRUCache
  # Node class to represent entries in the doubly linked list
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initializes the cache with the given capacity
  #
  # @param capacity [Integer] maximum number of items the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {} # Hash map for O(1) key lookups
    @head = Node.new(nil, nil) # Dummy head node
    @tail = Node.new(nil, nil) # Dummy tail node
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value associated with the given key
  #
  # @param key [Object] the key to retrieve
  # @return [Object, nil] the value if found, nil otherwise
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the front (most recently used)
    remove_node(node)
    add_to_head(node)
    node.value
  end

  # Inserts or updates a key-value pair in the cache
  #
  # @param key [Object] the key to insert or update
  # @param value [Object] the value to associate with the key
  # @return [void]
  def put(key, value)
    if @cache.key?(key)
      # Update existing key
      node = @cache[key]
      node.value = value
      remove_node(node)
      add_to_head(node)
    else
      # Insert new key
      if @cache.size >= @capacity
        # Evict the least recently used item (before tail)
        lru_node = @tail.prev
        @cache.delete(lru_node.key)
        remove_node(lru_node)
      end

      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_head(new_node)
    end
  end

  private

  # Adds a node to the front of the linked list (after head)
  #
  # @param node [Node] the node to add
  def add_to_head(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Removes a node from the linked list
  #
  # @param node [Node] the node to remove
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end
end