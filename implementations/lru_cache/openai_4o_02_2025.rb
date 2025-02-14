require 'forwardable'

class LRUCache
  extend Forwardable

  def_delegators :@store, :size, :empty?

  def initialize(capacity)
    raise ArgumentError, "Capacity must be greater than zero" unless capacity.positive?

    @capacity = capacity
    @store = {}
    @order = []
  end

  def get(key)
    return nil unless @store.key?(key)

    touch(key)
    @store[key]
  end

  def put(key, value)
    if @store.key?(key)
      @store[key] = value
      touch(key)
    else
      evict! if @store.size >= @capacity
      @store[key] = value
      @order << key
    end
  end

  private

  def touch(key)
    @order.delete(key)
    @order << key
  end

  def evict!
    lru_key = @order.shift
    @store.delete(lru_key)
  end
end
