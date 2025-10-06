require 'set'

class PriorityQueue
  def initialize
    @heap = []
  end

  def empty?
    @heap.empty?
  end

  def push(dist, node)
    @heap << [dist, node]
    _sift_up(@heap.size - 1)
  end

  def pop
    return nil if @heap.empty?
    min = @heap[0]
    last = @heap.pop
    @heap[0] = last unless @heap.empty?
    _sift_down(0) unless @heap.empty?
    min
  end

  private

  def _sift_up(i)
    while i > 0
      parent = (i - 1) >> 1
      break if @heap[i][0] >= @heap[parent][0]
      _swap(i, parent)
      i = parent
    end
  end

  def _sift_down(i)
    size = @heap.size
    while true
      left = (i << 1) + 1
      right = left + 1
      smallest = i
      if left < size && @heap[left][0] < @heap[smallest][0]
        smallest = left
      end
      if right < size && @heap[right][0] < @heap[smallest][0]
        smallest = right
      end
      break if smallest == i
      _swap(i, smallest)
      i = smallest
    end
  end

  def _swap(a, b)
    @heap[a], @heap[b] = @heap[b], @heap[a]
  end
end

class GraphShortestPaths
  INF = 1_000_000_000_000_000_000

  def self.compute(graph, source)
    nodes = Set.new
    graph.each_key { |k| nodes.add(k) }
    graph.each_value do |neighbors|
      neighbors&.each { |v, _| nodes.add(v) }
    end
    nodes.add(source)
    dist = nodes.to_h { |v| [v, INF] }
    dist[source] = 0
    pq = PriorityQueue.new
    pq.push(0, source)
    while (entry = pq.pop)
      d, u = entry
      next if d > dist[u]
      neighbors = graph[u]
      next unless neighbors
      neighbors.each do |v, w|
        alt = d + w
        if alt < dist[v]
          dist[v] = alt
          pq.push(alt, v)
        end
      end
    end
    dist
  end
end