# LRUCache
#
# An implementation of a Least Recently Used (LRU) cache with O(1) time complexity
# for both get and put operations using a combination of a Hash for quick lookups
# and a doubly linked list for maintaining the order of usage.
#
# @example Basic usage
#   cache = LRUCache.new(2)
#   cache.put(1, 1)           # Cache: {1: 1}
#   cache.put(2, 2)           # Cache: {1: 1, 2: 2}
#   cache.get(1)              # Returns 1, Cache: {2: 2, 1: 1} (1 is now most recently used)
#   cache.put(3, 3)           # Removes key 2, Cache: {1: 1, 3: 3}
#   cache.get(2)              # Returns nil (not found)
#   cache.put(4, 4)           # Removes key 1, Cache: {3: 3, 4: 4}
#   cache.get(1)              # Returns nil (not found)
#   cache.get(3)              # Returns 3, Cache: {4: 4, 3: 3}
#   cache.get(4)              # Returns 4, Cache: {3: 3, 4: 4}
#
class LRUCache
  # Node class for the doubly linked list
  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key = nil, value = nil)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initialize a new LRU cache with the specified capacity
  #
  # @param capacity [Integer] the maximum number of key-value pairs the cache can hold
  def initialize(capacity)
    @capacity = capacity
    @cache = {}         # Hash to store key -> node mappings for O(1) lookups
    @size = 0           # Current number of key-value pairs in the cache

    # Initialize empty doubly linked list with dummy head and tail nodes
    @head = Node.new    # Dummy head - newest items go after head
    @tail = Node.new    # Dummy tail - oldest items go before tail
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieve a value from the cache and mark it as most recently used
  #
  # @param key [Object] the key to look up
  # @return [Object, nil] the value associated with the key, or nil if not found
  def get(key)
    return nil unless @cache.key?(key)

    # Move node to front (most recently used position)
    node = @cache[key]
    remove_node(node)
    add_to_front(node)

    node.value
  end

  # Insert or update a key-value pair in the cache
  # If the cache is at capacity and a new key is added, remove the least recently used item
  #
  # @param key [Object] the key to insert or update
  # @param value [Object] the value to associate with the key
  def put(key, value)
    # If key exists, update its value and move to front
    if @cache.key?(key)
      node = @cache[key]
      node.value = value

      # Move to front (most recently used position)
      remove_node(node)
      add_to_front(node)
    else
      # If at capacity, remove the least recently used item (the one before tail)
      if @size == @capacity
        lru_node = @tail.prev
        remove_node(lru_node)
        @cache.delete(lru_node.key)
        @size -= 1
      end

      # Create new node and add to front
      new_node = Node.new(key, value)
      add_to_front(new_node)
      @cache[key] = new_node
      @size += 1
    end
  end

  private

  # Remove a node from the doubly linked list
  #
  # @param node [Node] the node to remove
  def remove_node(node)
    prev_node = node.prev
    next_node = node.next

    prev_node.next = next_node
    next_node.prev = prev_node
  end

  # Add a node to the front of the doubly linked list (after the dummy head)
  #
  # @param node [Node] the node to add to the front
  def add_to_front(node)
    node.prev = @head
    node.next = @head.next

    @head.next.prev = node
    @head.next = node
  end
end
