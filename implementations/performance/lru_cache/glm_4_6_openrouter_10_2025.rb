# LRUCache - A fixed-size cache that evicts the Least Recently Used (LRU) entry
# when its capacity is exceeded.
#
# Example:
#   cache = LRUCache.new(3)
#   cache.put(:a, 1)
#   cache.put(:b, 2)
#   cache.get(:a)          # => 1 (marks :a as most recently used)
#   cache.put(:c, 3)
#   cache.put(:d, 4)       # evicts :b (least recently used)
#
# All operations (get and put) run in O(1) time.
class LRUCache
  # Internal node used by the doubly linked list.
  Node = Struct.new(:key, :value, :prev, :next)

  # Creates a new LRU cache with the given capacity.
  #
  # @param capacity [Integer] maximum number of entries the cache can hold.
  # @raise [ArgumentError] if capacity is not a positive integer.
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @map = {}                # key => Node
    @size = 0

    # Dummy head and tail nodes to avoid edge-case checks.
    @head = Node.new(nil, nil, nil, nil)
    @tail = Node.new(nil, nil, nil, nil)
    @head.next = @tail
    @tail.prev = @head
  end

  # Retrieves the value for +key+ and marks the entry as most recently used.
  #
  # @param key [Object] the key to look up.
  # @return [Object] the associated value, or +nil+ if the key is not present.
  def get(key)
    node = @map[key]
    return nil unless node

    move_to_head(node)
    node.value
  end

  # Inserts or updates the value for +key+. If inserting a new key exceeds
  # the cache's capacity, the least recently used entry is evicted.
  #
  # @param key [Object] the key to insert or update.
  # @param value [Object] the value to associate with +key+.
  # @return [void]
  def put(key, value)
    node = @map[key]

    if node
      node.value = value
      move_to_head(node)
    else
      new_node = Node.new(key, value, nil, nil)
      @map[key] = new_node
      add_to_head(new_node)
      @size += 1

      if @size > @capacity
        tail_node = pop_tail
        @map.delete(tail_node.key)
        @size -= 1
      end
    end

    nil
  end

  private

  # Removes +node+ from its current position in the linked list.
  def remove_node(node)
    prev_node = node.prev
    next_node = node.next
    prev_node.next = next_node
    next_node.prev = prev_node
  end

  # Inserts +node+ right after the dummy head (most recent position).
  def add_to_head(node)
    node.prev = @head
    node.next = @head.next
    @head.next.prev = node
    @head.next = node
  end

  # Moves an existing +node+ to the head of the list.
  def move_to_head(node)
    remove_node(node)
    add_to_head(node)
  end

  # Removes and returns the least recently used node (just before the dummy tail).
  def pop_tail
    last_node = @tail.prev
    remove_node(last_node)
    last_node
  end
end