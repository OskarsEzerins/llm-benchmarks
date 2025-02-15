class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @lru_list = []
  end

  def get(key)
    if @cache.key?(key)
      @lru_list.delete(key)
      @lru_list.push(key)
      @cache[key]
    else
      nil
    end
  end

  def put(key, value)
    if @cache.key?(key)
      @lru_list.delete(key)
    elsif @cache.size >= @capacity
      lru_key = @lru_list.shift
      @cache.delete(lru_key)
    end
    @cache[key] = value
    @lru_list.push(key)
  end
end
