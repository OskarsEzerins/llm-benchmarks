# frozen_string_literal: true

# LRUCache implements a Least Recently Used (LRU) cache with O(1) time complexity
# for both get and put operations using a hash map and doubly linked list.
#
# Example usage:
#   cache = LRUCache.new(3)
#   cache.put(:a, 1)
#   cache.put(:b, 2)
#   cache.get(:a)    # => 1
#   cache.put(:c, 3) # Evicts :b (least recently used)
#   cache.get(:b)    # => nil
class LRUCache
  # Node represents an entry in the doubly linked list
  Node = Struct.new(:key, :value, :prev, :next)

  # Creates a new LRU cache with the given capacity
  # @param capacity [Integer] maximum number of entries the cache can hold
  # @raise [ArgumentError] if capacity is not positive
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be positive' unless capacity.positive?

    @capacity = capacity
    @size = 0
    @map = {}
    @head = Node.new(nil, nil, nil, nil) # Dummy head (most recent)
    @tail = Node.new(nil, nil, nil, nil) # Dummy tail (least recent)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value for the given key and marks it as most recently used
  # @param key [Object] the key to look up
  # @return [Object, nil] the value if found, nil otherwise
  def get(key)
    node = @map[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Inserts or updates a key-value pair. If the cache exceeds capacity,
  # the least recently used entry is evicted.
  # @param key [Object] the key to store
  # @param value [Object] the value to store
  def put(key, value)
    node = @map[key]

    if node
      node.value = value
      move_to_head(node)
    else
      new_node = Node.new(key, value, @head, @head.next)
      @head.next.prev = new_node
      @head.next = new_node
      @map[key] = new_node
      @size += 1

      if @size > @capacity
        lru = @tail.prev
        remove_node(lru)
        @map.delete(lru.key)
        @size -= 1
      end
    end
  end

  private

  # Adds a node right after the head (most recent position)
  def add_node(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Removes a node from the linked list
  def remove_node(node)
    node.prev.next = node.next
    node.next.prev = node.prev
  end

  # Moves an existing node to the head (most recent position)
  def move_to_head(node)
    remove_node(node)
    add_node(node)
  end
end