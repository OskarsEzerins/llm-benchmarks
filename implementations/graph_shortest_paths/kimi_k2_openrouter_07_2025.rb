class GraphShortestPaths
  class FastHeap
    Node = Struct.new(:key, :value)

    def initialize
      @heap = []
      @index = {}
    end

    def push(key, value)
      node = Node.new(key, value)
      @heap << node
      @index[key] = @heap.size - 1
      up(@heap.size - 1)
    end

    def decrease_key(key, new_value)
      idx = @index[key]
      return unless idx
      if new_value < @heap[idx].value
        @heap[idx].value = new_value
        up(idx)
      end
    end

    def pop
      return nil if @heap.empty?
      min = @heap[0]
      last = @heap.pop
      unless @heap.empty?
        @heap[0] = last
        @index[last.key] = 0
        down(0)
      end
      @index.delete(min.key)
      [min.key, min.value]
    end

    def empty?
      @heap.empty?
    end

    private

    def up(idx)
      while idx > 0
        parent = (idx - 1) / 2
        break if @heap[parent].value <= @heap[idx].value
        swap(parent, idx)
        idx = parent
      end
    end

    def down(idx)
      size = @heap.size
      loop do
        left = 2 * idx + 1
        right = 2 * idx + 2
        smallest = idx

        smallest = left if left < size && @heap[left].value < @heap[smallest].value
        smallest = right if right < size && @heap[right].value < @heap[smallest].value
        break if smallest == idx

        swap(idx, smallest)
        idx = smallest
      end
    end

    def swap(i, j)
      @index[@heap[i].key] = j
      @index[@heap[j].key] = i
      @heap[i], @heap[j] = @heap[j], @heap[i]
    end
  end

  def self.compute(graph, source)
    dist = {}
    graph.each_key { |u| dist[u] = Float::INFINITY }
    dist[source] = 0

    pq = FastHeap.new
    pq.push(source, 0)

    until pq.empty?
      u, _ = pq.pop
      next unless graph.key?(u)

      graph[u].each do |(v, weight)|
        next unless dist.key?(v)
        alt = dist[u] + weight
        if alt < dist[v]
          dist[v] = alt
          if pq.instance_variable_get(:@index).key?(v)
            pq.decrease_key(v, alt)
          else
            pq.push(v, alt)
          end
        end
      end
    end

    dist
  end
end