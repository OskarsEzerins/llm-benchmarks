class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @cache = {}
    @lru_keys = []
  end

  def get(key)
    if @cache.key?(key)
      @lru_keys.delete(key)
      @lru_keys.push(key)
      @cache[key]
    else
      nil
    end
  end

  def put(key, value)
    if @cache.key?(key)
      @lru_keys.delete(key)
    elsif @cache.size >= @capacity
      evict_key = @lru_keys.shift
      @cache.delete(evict_key)
    end
    @cache[key] = value
    @lru_keys.push(key)
  end

  private

  def evict
    evict_key = @lru_keys.shift
    @cache.delete(evict_key)
  end
end