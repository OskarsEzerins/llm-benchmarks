class GraphShortestPaths
  class PriorityQueue
    def initialize
      @h = []
    end

    def push(d,u)
      h = @h
      i = h.size
      h[i] = [d,u]
      while i > 0
        p = (i - 1) >> 1
        if h[p][0] > h[i][0]
          h[p], h[i] = h[i], h[p]
          i = p
        else
          break
        end
      end
    end

    def pop
      h = @h
      return if h.empty?
      min = h[0]
      last = h.pop
      if h.size > 0
        h[0] = last
        i = 0
        sz = h.size
        loop do
          l = (i << 1) + 1
          r = l + 1
          m = i
          m = l if l < sz && h[l][0] < h[m][0]
          m = r if r < sz && h[r][0] < h[m][0]
          break if m == i
          h[i], h[m] = h[m], h[i]
          i = m
        end
      end
      min
    end
  end

  def self.compute(graph, source)
    inf = Float::INFINITY
    dist = {}
    graph.each_key { |n| dist[n] = inf }
    dist[source] = 0
    pq = PriorityQueue.new
    pq.push(0, source)
    while entry = pq.pop
      d, u = entry
      next if d > dist[u]
      nbrs = graph[u]
      next unless nbrs
      nbrs.each do |v, w|
        nd = d + w
        if nd < (dv = dist[v] || inf)
          dist[v] = nd
          pq.push(nd, v)
        end
      end
    end
    dist
  end
end