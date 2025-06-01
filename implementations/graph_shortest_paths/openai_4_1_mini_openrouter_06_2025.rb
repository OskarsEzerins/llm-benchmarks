class GraphShortestPaths
  class MinHeap
    def initialize(capacity)
      @heap = Array.new(capacity)
      @size = 0
    end

    def push(node, dist)
      idx = @size
      @size += 1
      @heap[idx] = [node, dist]
      sift_up(idx)
    end

    def pop
      return nil if @size == 0
      root = @heap[0]
      @size -= 1
      if @size > 0
        @heap[0] = @heap[@size]
        sift_down(0)
      end
      root
    end

    def empty?
      @size == 0
    end

    private

    def sift_up(idx)
      h = @heap
      item = h[idx]
      while idx > 0
        parent = (idx - 1) >> 1
        break if h[parent][1] <= item[1]
        h[idx] = h[parent]
        idx = parent
      end
      h[idx] = item
    end

    def sift_down(idx)
      h = @heap
      size = @size
      item = h[idx]
      half = size >> 1
      while idx < half
        left = (idx << 1) + 1
        right = left + 1
        smaller = right < size && h[right][1] < h[left][1] ? right : left
        break if h[smaller][1] >= item[1]
        h[idx] = h[smaller]
        idx = smaller
      end
      h[idx] = item
    end
  end

  def self.compute(graph, source)
    dist = {}
    dist.default = Float::INFINITY
    dist[source] = 0
    heap = MinHeap.new(graph.size)
    heap.push(source, 0)

    while !heap.empty?
      u, du = heap.pop
      next if du > dist[u]

      neighbors = graph[u]
      next unless neighbors

      neighbors.each do |v, w|
        nd = du + w
        if nd < dist[v]
          dist[v] = nd
          heap.push(v, nd)
        end
      end
    end

    dist
  end
end