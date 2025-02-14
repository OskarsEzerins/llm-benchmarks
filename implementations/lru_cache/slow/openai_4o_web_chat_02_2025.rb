require 'thread'

class LRUCache
  def initialize(capacity)
    @capacity = capacity
    @store = {}
    @order = []
    @lock = Mutex.new
  end

  def get(key)
    @lock.synchronize do
      return nil unless @store.key?(key)

      touch_key(key)
      @store[key]
    end
  end

  def put(key, value)
    @lock.synchronize do
      if @store.key?(key)
        @store[key] = value
        touch_key(key)
      else
        evict_lru if @store.size >= @capacity
        @store[key] = value
        @order << key
      end
    end
  end

  private

  def touch_key(key)
    @order.delete(key)
    @order << key
  end

  def evict_lru
    lru_key = @order.shift
    @store.delete(lru_key) if lru_key
  end
end
