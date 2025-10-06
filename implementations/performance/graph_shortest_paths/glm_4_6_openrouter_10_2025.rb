class GraphShortestPaths
  class MinHeap
    def initialize
      @heap = []
    end

    def push(item)
      @heap << item
      _siftdown(@heap.size - 1)
    end

    def pop
      return nil if @heap.empty?
      min = @heap[0]
      last = @heap.pop
      if @heap.size > 0
        @heap[0] = last
        _siftup(0)
      end
      min
    end

    def empty?
      @heap.empty?
    end

    private

    def _siftdown(idx)
      item = @heap[idx]
      dist = item[0]
      while idx > 0
        parent = (idx - 1) >> 1
        parent_dist = @heap[parent][0]
        break if parent_dist <= dist
        @heap[idx] = @heap[parent]
        idx = parent
      end
      @heap[idx] = item
    end

    def _siftup(idx)
      size = @heap.size
      item = @heap[idx]
      dist = item[0]
      half = size >> 1
      while idx < half
        left = (idx << 1) + 1
        right = left + 1
        best = left
        best_dist = @heap[left][0]
        if right < size && @heap[right][0] < best_dist
          best = right
          best_dist = @heap[right][0]
        end
        break if best_dist >= dist
        @heap[idx] = @heap[best]
        idx = best
      end
      @heap[idx] = item
    end
  end

  def self.compute(graph, source)
    max_id = source
    graph.each_key do |node|
      max_id = node if node > max_id
      graph[node].each do |nbr, _|
        max_id = nbr if nbr > max_id
      end
    end

    INF = Float::INFINITY
    dist = Array.new(max_id + 1, INF)
    dist[source] = 0

    heap = MinHeap.new
    heap.push([0, source])

    g = graph
    while (item = heap.pop)
      d, u = item
      next if d != dist[u]

      adj = g[u]
      next unless adj
      adj.each do |v, w|
        nd = d + w
        if nd < dist[v]
          dist[v] = nd
          heap.push([nd, v])
        end
      end
    end

    result = {}
    i = 0
    while i <= max_id
      d = dist[i]
      result[i] = d if d != INF
      i += 1
    end
    result
  end
end