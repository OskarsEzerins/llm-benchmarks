class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @head = nil
    @tail = nil
  end

  def get(key)
    node = @cache[key]
    return nil unless node

    move_to_head(node)
    node[:value]
  end

  def put(key, value)
    if @cache.key?(key)
      node = @cache[key]
      node[:value] = value
      move_to_head(node)
    else
      new_node = { key: key, value: value, prev: nil, next: nil }
      @cache[key] = new_node

      if @cache.size > @capacity
        evict_least_recently_used
      end

      add_to_head(new_node)
    end
  end

  private

  def add_to_head(node)
    if @head.nil?
      @head = @tail = node
    else
      node[:next] = @head
      @head[:prev] = node
      @head = node
    end
  end

  def remove_node(node)
    if node[:prev]
      node[:prev][:next] = node[:next]
    else
      @head = node[:next]
    end

    if node[:next]
      node[:next][:prev] = node[:prev]
    else
      @tail = node[:prev]
    end
  end

  def move_to_head(node)
    remove_node(node)
    add_to_head(node)
  end

  def evict_least_recently_used
    lru_node = @tail
    remove_node(lru_node)
    @cache.delete(lru_node[:key])
  end
end
