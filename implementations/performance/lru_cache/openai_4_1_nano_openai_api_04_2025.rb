require 'benchmark'

# LRUCache implements a Least Recently Used (LRU) cache with O(1) access time.
#
# Usage:
#   cache = LRUCache.new(capacity)
#   cache.get(key) -> returns value or nil if not found
#   cache.put(key, value) -> inserts or updates key with value
#
# Internally, it uses a Hash for fast lookups and a doubly linked list to track usage order.
class LRUCache
  # Node class represents each cache entry in the doubly linked list
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize the cache with a maximum capacity
  #
  # @param capacity [Integer] maximum number of items to store
  def initialize(capacity)
    @capacity = capacity
    @map = {} # Hash for O(1) key lookups
    # Dummy head and tail nodes to simplify list operations
    @head = Node.new(nil, nil)
    @tail = Node.new(nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve the value for the given key.
  # If found, moves the node to the head (most recently used).
  #
  # @param key [Object] key to retrieve
  # @return [Object, nil] value associated with key, or nil if not found
  def get(key)
    node = @map[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Insert or update the key with the provided value.
  # If the cache exceeds capacity, removes the least recently used item.
  #
  # @param key [Object] key to insert/update
  # @param value [Object] value to associate with the key
  def put(key, value)
    node = @map[key]
    if node
      node.value = value
      move_to_head(node)
    else
      new_node = Node.new(key, value)
      @map[key] = new_node
      add_to_head(new_node)
      if @map.size > @capacity
        evicted_node = remove_tail
        @map.delete(evicted_node.key)
      end
    end
  end

  private

  # Adds a node right after the dummy head.
  #
  # @param node [Node] the node to add
  def add_to_head(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Removes a node from the linked list.
  #
  # @param node [Node] the node to remove
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Moves a node to the head (most recently used position).
  #
  # @param node [Node] the node to move
  def move_to_head(node)
    remove_node(node)
    add_to_head(node)
  end

  # Removes the tail node (least recently used) and returns it.
  #
  # @return [Node] the removed node
  def remove_tail
    node = @tail.prev
    remove_node(node)
    node
  end
end
