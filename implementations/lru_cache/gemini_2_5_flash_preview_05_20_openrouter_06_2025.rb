# Implements an LRU Cache with a fixed maximum capacity.
#
# The cache uses a combination of a Hash and a doubly linked list to achieve
# O(1) time complexity for both `get` and `put` operations.
#
# The Hash (`@cache`) stores key-value pairs, where the value is a Node object
# from the doubly linked list. This allows for O(1) lookup of a key's
# corresponding node.
#
# The doubly linked list (`@head` and `@tail`) maintains the order of
# recently used keys. The `@head` points to the most recently used key, and
# the `@tail` points to the least recently used key.
#
# When a key is accessed (via `get` or `put`), its corresponding node is moved
# to the head of the list, marking it as most recently used.
#
# When the cache exceeds its capacity during a `put` operation, the node at
# the `@tail` (least recently used) is evicted.
class LRUCache
  # Represents a node in the doubly linked list.
  # Each node stores a key and its associated value.
  # It also has pointers to the previous and next nodes in the list.
  class Node
    attr_accessor :key, :value, :prev, :next

    # Initializes a new Node.
    # @param key [Object] The key for the cache entry.
    # @param value [Object] The value associated with the key.
    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  # Initializes a new LRUCache instance.
  # @param capacity [Integer] The maximum number of key-value pairs the cache can hold.
  # @raise [ArgumentError] if capacity is not a positive integer.
  def initialize(capacity)
    raise ArgumentError, 'Capacity must be a positive integer' unless capacity.is_a?(Integer) && capacity > 0

    @capacity = capacity
    @cache = {} # Stores key -> Node mapping for O(1) lookup
    @head = nil # Head of the doubly linked list (most recently used)
    @tail = nil # Tail of the doubly linked list (least recently used)
    @size = 0   # Current number of elements in the cache
  end

  # Retrieves the value associated with the given key.
  # If the key is found, it marks the key as most recently used.
  #
  # @param key [Object] The key to look up.
  # @return [Object, nil] The value associated with the key, or nil if the key is not found.
  # @example
  #   cache = LRUCache.new(2)
  #   cache.put(1, 'a')
  #   cache.put(2, 'b')
  #   cache.get(1) # => 'a' (1 is now MRU)
  #   cache.get(3) # => nil
  def get(key)
    node = @cache[key]
    return nil unless node

    # Move the accessed node to the head of the list
    move_to_head(node)
    node.value
  end

  # Inserts a new key-value pair or updates an existing key's value.
  # If inserting a new key causes the cache to exceed its capacity,
  # the least recently used key is automatically evicted.
  #
  # @param key [Object] The key to insert or update.
  # @param value [Object] The value to associate with the key.
  # @example
  #   cache = LRUCache.new(2)
  #   cache.put(1, 'a') # Cache: {1: 'a'}
  #   cache.put(2, 'b') # Cache: {1: 'a', 2: 'b'}
  #   cache.put(3, 'c') # Cache: {2: 'b', 3: 'c'} (1 was evicted)
  #   cache.get(2)      # => 'b' (2 is now MRU)
  #   cache.put(2, 'new_b') # Cache: {3: 'c', 2: 'new_b'} (2's value updated, 2 is MRU)
  def put(key, value)
    node = @cache[key]

    if node # Key already exists, update value and move to head
      node.value = value
      move_to_head(node)
    else # New key
      # Evict LRU if capacity is reached
      if @size >= @capacity
        remove_tail # Evict the least recently used node
      end

      # Create new node and add it to cache and head
      new_node = Node.new(key, value)
      @cache[key] = new_node
      add_to_head(new_node)
      @size += 1
    end
  end

  private

  # Adds a node to the head of the doubly linked list.
  # This node becomes the most recently used.
  # @param node [Node] The node to add.
  def add_to_head(node)
    if @head.nil? # Cache is empty
      @head = node
      @tail = node
    else
      node.next = @head
      @head.prev = node
      @head = node
    end
  end

  # Removes a node from the doubly linked list.
  # @param node [Node] The node to remove.
  def remove_node(node)
    if node == @head && node == @tail # Only one node in list
      @head = nil
      @tail = nil
    elsif node == @head # Node is the head
      @head = node.next
      @head.prev = nil
    elsif node == @tail # Node is the tail
      @tail = node.prev
      @tail.next = nil
    else # Node is in the middle
      node.prev.next = node.next
      node.next.prev = node.prev
    end
    node.prev = nil # Clear pointers for removed node
    node.next = nil
  end

  # Moves an existing node to the head of the doubly linked list.
  # This makes the node the most recently used.
  # @param node [Node] The node to move.
  def move_to_head(node)
    return if node == @head # Already at the head

    remove_node(node)
    add_to_head(node)
  end

  # Removes the tail node from the doubly linked list.
  # This effectively evicts the least recently used key from the cache.
  def remove_tail
    return if @tail.nil? # Cache is empty

    lru_key = @tail.key
    remove_node(@tail)
    @cache.delete(lru_key)
    @size -= 1
  end
end