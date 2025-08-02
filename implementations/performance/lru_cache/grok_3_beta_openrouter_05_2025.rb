# LRUCache class implementing a Least Recently Used cache with O(1) time complexity
# for both get and put operations using a combination of a hash map and a doubly linked list.
#
# == Overview
# The LRUCache maintains a fixed capacity of key-value pairs. When the cache reaches
# its capacity, the least recently used item is evicted to make room for new entries.
# The implementation uses:
# - A Hash for O(1) key-value lookups
# - A doubly linked list for O(1) updates of the usage order
#
# == Usage
#   cache = LRUCache.new(2)  # Create cache with capacity of 2
#   cache.put(1, 1)          # Cache is {1=>1}
#   cache.put(2, 2)          # Cache is {1=>1, 2=>2}
#   cache.get(1)             # Returns 1
#   cache.put(3, 3)          # Evicts key 2, cache is {1=>1, 3=>3}
#   cache.get(2)             # Returns nil (not found)
#
# == Time Complexity
# - get(key): O(1) - Direct hash lookup and list node movement
# - put(key, value): O(1) - Hash update and list node movement or creation
class LRUCache
  # Node class for doubly linked list to track usage order
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize the cache with a given capacity
  #
  # @param capacity [Integer] Maximum number of key-value pairs the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {}  # Hash map for O(1) key-value lookup
    # Dummy head and tail nodes for easier list manipulation
    @head = Node.new(0, 0)
    @tail = Node.new(0, 0)
    @head.next = @tail
    @tail.prev = @head
  end

  # Get the value associated with a key if it exists
  #
  # @param key [Object] Key to look up
  # @return [Object, nil] Value associated with key, or nil if not found
  def get(key)
    return nil unless @cache.key?(key)

    node = @cache[key]
    move_to_front(node)
    node.value
  end

  # Insert or update a key-value pair in the cache
  #
  # @param key [Object] Key to insert or update
  # @param value [Object] Value to associate with the key
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      move_to_front(node)
    else
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_front(new_node)
      evict_if_needed
    end
  end

  private

  # Add a node to the front of the doubly linked list (most recently used)
  #
  # @param node [Node] Node to add
  def add_to_front(node)
    node.next = @head.next
    node.prev = @head
    @head.next.prev = node
    @head.next = node
  end

  # Remove a node from the doubly linked list
  #
  # @param node [Node] Node to remove
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Move a node to the front of the list (mark as most recently used)
  #
  # @param node [Node] Node to move
  def move_to_front(node)
    remove_node(node)
    add_to_front(node)
  end

  # Evict the least recently used item if cache exceeds capacity
  def evict_if_needed
    return if @cache.size <= @capacity

    lru_node = @tail.prev
    remove_node(lru_node)
    @cache.delete(lru_node.key)
  end
end