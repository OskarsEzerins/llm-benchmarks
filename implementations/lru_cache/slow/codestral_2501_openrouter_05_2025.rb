class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @order = []
  end

  def get(key)
    return nil unless @cache.key?(key)

    @order.delete(key)
    @order << key
    @cache[key]
  end

  def put(key, value)
    if @cache.key?(key)
      @order.delete(key)
    elsif @order.size >= @capacity
      lru_key = @order.shift
      @cache.delete(lru_key)
    end

    @order << key
    @cache[key] = value
  end
end