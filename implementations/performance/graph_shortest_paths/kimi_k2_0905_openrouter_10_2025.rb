class GraphShortestPaths
  def self.compute(graph, source)
    dist = {}
    heap = FastBinaryHeap.new
    graph.each_key { |v| dist[v] = Float::INFINITY }
    dist[source] = 0
    heap.push(0, source)
    until heap.empty?
      d, u = heap.pop
      next if d > dist[u]
      graph[u]&.each do |v, w|
        nd = d + w
        if nd < dist[v]
          dist[v] = nd
          heap.push(nd, v)
        end
      end
    end
    dist
  end

  class FastBinaryHeap
    def initialize
      @a = []
    end

    def push(key, value)
      @a << [key, value]
      i = @a.size - 1
      while i > 0
        p = (i - 1) >> 1
        break if @a[p][0] <= key
        @a[i] = @a[p]
        i = p
      end
      @a[i] = [key, value]
    end

    def pop
      return nil if @a.empty?
      top = @a[0]
      last = @a.pop
      unless @a.empty?
        key = last[0]
        @a[0] = last
        i = 0
        loop do
          l = (i << 1) + 1
          r = l + 1
          smallest = i
          smallest = l if l < @a.size && @a[l][0] < @a[smallest][0]
          smallest = r if r < @a.size && @a[r][0] < @a[smallest][0]
          break if smallest == i
          @a[i], @a[smallest] = @a[smallest], @a[i]
          i = smallest
        end
      end
      top
    end

    def empty?
      @a.empty?
    end
  end
end