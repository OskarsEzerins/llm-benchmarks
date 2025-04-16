class GraphShortestPaths
  class MinHeap
    def initialize(capacity)
      @heap = Array.new(capacity)
      @size = 0
    end

    def push(node, dist)
      i = @size
      @size += 1
      @heap[i] = [node, dist]
      sift_up(i)
    end

    def pop
      return if @size == 0
      top = @heap[0]
      @size -= 1
      if @size > 0
        @heap[0] = @heap[@size]
        sift_down(0)
      end
      top
    end

    def empty?
      @size == 0
    end

    private

    def sift_up(i)
      h = @heap
      x = h[i]
      while i > 0
        p = (i - 1) >> 1
        break if h[p][1] <= x[1]
        h[i] = h[p]
        i = p
      end
      h[i] = x
    end

    def sift_down(i)
      h = @heap
      size = @size
      x = h[i]
      loop do
        l = (i << 1) + 1
        r = l + 1
        break if l >= size
        smallest = (r < size && h[r][1] < h[l][1]) ? r : l
        break if x[1] <= h[smallest][1]
        h[i] = h[smallest]
        i = smallest
      end
      h[i] = x
    end
  end

  def self.compute(graph, source)
    n = graph.keys.max || 0
    dist = Array.new(n + 1, nil)
    dist[source] = 0
    heap = MinHeap.new(graph.size)
    heap.push(source, 0)

    while !heap.empty?
      u, du = heap.pop
      next if dist[u] != du
      (graph[u] || EMPTY).each do |v, w|
        dv = du + w
        if dist[v].nil? || dv < dist[v]
          dist[v] = dv
          heap.push(v, dv)
        end
      end
    end

    dist
  end

  EMPTY = [].freeze
end
