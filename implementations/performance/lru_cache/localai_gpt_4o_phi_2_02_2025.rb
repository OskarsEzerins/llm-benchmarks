# Implement a Least Recently Used (LRU) Cache

class LRUCache
    def initialize(capacity)
        @capacity = capacity
        @cache = Hash.new { |h, k| h[k] = List.new }
    end

    def get(key)
        if (value = @cache[key])
            value.front
            value.back
        end
    end

    def put(key, value)
        if @cache[key]
            @cache[key].remove(key)
        elsif @cache.length >= @capacity
            WorstScan.new(@cache.values).delete_rightmost
        end

        @cache[key] = List.new(key, value)
    end
end

class List
    def initialize(*items)
        @storage = []
        items.each { |e| push(e) }
    end

    def front
        @storage.shift
    end

    def remove(el)
        @storage.delete(el)
    end

    def back
        @storage.pop
    end

    def push(*items)
        @storage.concat(items)
    end
    attr_reader :head, :tail
end

class ListScan
    attr_reader :list_node

    def initialize(list)
        @list = list
        @current = list.head
    end

    def delete_rightmost
        @list.tail = @current.prev
        @current.val = nil
        @current = @list.tail
    end
end

class WorstScan < ListScan
    def delete_rightmost
        while(@current.next != @list.tail)
            if(@current.val.is_a?(List))
                WorstScan.new(@current.val).delete_rightmost
            end

            @current = @current.next
        end

        @list.tail = @current
        @current.val = nil
    end
end
