class GraphShortestPaths
  def self.compute(graph, source)
    dist = {}
    pq = PriorityQueue.new
    dist[source] = 0
    pq.push(source, 0)
    while (pair = pq.pop)
      u, du = pair
      next if du != dist[u]
      if graph[u]
        graph[u].each do |v, w|
          dv = du + w
          prev = dist[v]
          if prev.nil? || dv < prev
            dist[v] = dv
            pq.push(v, dv)
          end
        end
      end
    end
    dist
  end

  class PriorityQueue
    def initialize
      @h = []
    end

    def push(node, dist)
      h = @h
      i = h.size
      h << nil
      n = node; d = dist
      while i > 0
        p = (i - 1) >> 1
        break if h[p][1] <= d
        h[i] = h[p]
        i = p
      end
      h[i] = [n, d]
    end

    def pop
      h = @h
      return nil if h.empty?
      top = h[0]
      last = h.pop
      return top if h.empty?
      ln, ld = last
      i = 0
      size = h.size
      loop do
        lc = (i << 1) + 1
        break if lc >= size
        rc = lc + 1
        c = (rc < size && h[rc][1] < h[lc][1]) ? rc : lc
        break if h[c][1] >= ld
        h[i] = h[c]
        i = c
      end
      h[i] = [ln, ld]
      top
    end
  end
end