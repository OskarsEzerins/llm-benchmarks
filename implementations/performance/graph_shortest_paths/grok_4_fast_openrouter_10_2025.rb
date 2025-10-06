class MinHeap
  def initialize
    @heap = []
  end

  def push(item)
    @heap << item
    sift_up(@heap.size - 1)
  end

  def pop
    return nil if empty?
    min = @heap[0]
    last = @heap.pop
    if !empty?
      @heap[0] = last
      sift_down(0)
    end
    min
  end

  def empty?
    @heap.empty?
  end

  private

  def sift_up(i)
    while i > 0
      p = (i - 1) / 2
      break if @heap[p] <= @heap[i]
      swap(p, i)
      i = p
    end
  end

  def sift_down(i)
    size = @heap.size
    while true
      l = 2 * i + 1
      r = 2 * i + 2
      smallest = i
      if l < size && @heap[l] < @heap[smallest]
        smallest = l
      end
      if r < size && @heap[r] < @heap[smallest]
        smallest = r
      end
      break if smallest == i
      swap(i, smallest)
      i = smallest
    end
  end

  def swap(a, b)
    @heap[a], @heap[b] = @heap[b], @heap[a]
  end
end

class GraphShortestPaths
  INF = 10**18

  def self.compute(graph, source)
    nodes = {}
    graph.each do |u, neighs|
      nodes[u] = true
      neighs.each { |v, _| nodes[v] = true }
    end
    nodes[source] = true

    dist = nodes.keys.to_h { |k| [k, INF] }
    dist[source] = 0

    heap = MinHeap.new
    heap.push([0, source])

    while !heap.empty?
      d, u = heap.pop
      next if d > dist[u]

      graph.fetch(u, []).each do |v, w|
        alt = d + w
        if alt < dist[v]
          dist[v] = alt
          heap.push([alt, v])
        end
      end
    end

    dist
  end
end