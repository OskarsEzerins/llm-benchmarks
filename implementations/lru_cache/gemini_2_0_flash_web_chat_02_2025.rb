class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @queue = DoublyLinkedQueue.new
  end

  # Retrieves a value from the cache.
  #
  # @param key [Object] The key to retrieve.
  # @return [Object, nil] The value associated with the key, or nil if not found.
  def get(key)
    node = @cache[key]
    return nil unless node

    @queue.move_to_front(node)
    node.value
  end

  # Inserts or updates a key-value pair in the cache.
  # If the cache is full, the least recently used item is evicted.
  #
  # @param key [Object] The key to insert or update.
  # @param value [Object] The value to associate with the key.
  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node.value = value
      @queue.move_to_front(node)
    else
      if @cache.size >= @capacity
        evicted_node = @queue.remove_last
        @cache.delete(evicted_node.key)
      end
      node = Node.new(key, value)
      @cache[key] = node
      @queue.add_to_front(node)
    end
  end

  private

  class Node
    attr_accessor :key, :value, :prev, :next

    def initialize(key, value)
      @key = key
      @value = value
      @prev = nil
      @next = nil
    end
  end

  class DoublyLinkedQueue
    def initialize
      @head = nil
      @tail = nil
    end

    def add_to_front(node)
      if @head.nil?
        @head = @tail = node
      else
        node.next = @head
        @head.prev = node
        @head = node
      end
    end

    def move_to_front(node)
      return if node == @head

      remove(node)
      add_to_front(node)
    end


    def remove(node)
      if node == @head
        @head = node.next
      end
      if node == @tail
        @tail = node.prev
      end
      if node.prev
        node.prev.next = node.next
      end
      if node.next
        node.next.prev = node.prev
      end
    end

    def remove_last
      return nil if @tail.nil?

      node = @tail
      if @head == @tail
        @head = @tail = nil
      else
        @tail = @tail.prev
        @tail.next = nil
      end
      node
    end
  end
end
