class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @order = []
  end

  def get(key)
    if @cache.key?(key)
      @order.delete(key)
      @order.push(key)
      return @cache[key]
    end
    nil
  end

  def put(key, value)
    if @cache.key?(key)
      @order.delete(key)
    elsif @cache.size >= @capacity
      lru_key = @order.shift
      @cache.delete(lru_key)
    end
    @cache[key] = value
    @order.push(key)
  end
end
