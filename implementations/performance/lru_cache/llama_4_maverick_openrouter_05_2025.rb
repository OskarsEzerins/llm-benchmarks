# frozen_string_literal: true

##
# A Least Recently Used (LRU) Cache implementation in Ruby.
#
# The cache is initialized with a maximum capacity and supports get and put operations.
# It uses a combination of a Hash and a Doubly Linked List to achieve O(1) time complexity for both operations.
class LRUCache
  ##
  # Node class representing a single element in the Doubly Linked List.
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
    end
  end

  ##
  # Initializes the LRU Cache with the given capacity.
  #
  # @param capacity [Integer] The maximum number of key-value pairs the cache can hold.
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  ##
  # Retrieves the value associated with the given key and marks it as most recently used.
  #
  # @param key [Object] The key to retrieve the value for.
  # @return [Object, nil] The value associated with the key, or nil if not found.
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the front of the list
    remove_node(node)
    add_node_to_front(node)
    node.value
  end

  ##
  # Inserts or updates a key-value pair in the cache.
  #
  # If inserting a new key causes the cache to exceed its capacity, the least recently used key is evicted.
  #
  # @param key [Object] The key to insert or update.
  # @param value [Object] The value associated with the key.
  def put(key, value)
    node = @cache[key]
    if node
      # Update the existing node's value and move it to the front
      node.value = value
      remove_node(node)
      add_node_to_front(node)
    else
      # Create a new node and add it to the front
      node = Node.new(key, value)
      @cache[key] = node
      add_node_to_front(node)

      # Evict the least recently used node if the cache is full
      remove_least_recently_used if @cache.size > @capacity
    end
  end

  private

  ##
  # Removes a node from the Doubly Linked List.
  #
  # @param node [Node] The node to remove.
  def remove_node(node)
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
  end

  ##
  # Adds a node to the front of the Doubly Linked List.
  #
  # @param node [Node] The node to add.
  def add_node_to_front(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  ##
  # Removes the least recently used node from the cache.
  def remove_least_recently_used
    lru_node = @tail.prev
    remove_node(lru_node)
    @cache.delete(lru_node.key)
  end
end