class PriorityQueue
  def initialize
    @heap = []
  end

  def push(node, priority)
    @heap << [priority, node]
    sift_up(@heap.size - 1)
  end

  def pop
    return nil if @heap.empty?
    top = @heap[0]
    last = @heap.pop
    if @heap.any?
      @heap[0] = last
      sift_down(0)
    end
    [top[1], top[0]]
  end

  def any?
    !@heap.empty?
  end

  private

  def sift_up(idx)
    while idx > 0
      parent = (idx - 1) >> 1
      break if @heap[parent][0] <= @heap[idx][0]
      @heap[parent], @heap[idx] = @heap[idx], @heap[parent]
      idx = parent
    end
  end

  def sift_down(idx)
    size = @heap.size
    loop do
      left = (idx << 1) + 1
      right = left + 1
      smallest = idx
      smallest = left if left < size && @heap[left][0] < @heap[smallest][0]
      smallest = right if right < size && @heap[right][0] < @heap[smallest][0]
      break if smallest == idx
      @heap[idx], @heap[smallest] = @heap[smallest], @heap[idx]
      idx = smallest
    end
  end
end

class GraphShortestPaths
  def self.compute(graph, source)
    dist = Hash.new(Float::INFINITY)
    dist[source] = 0
    pq = PriorityQueue.new
    pq.push(source, 0)

    while pq.any?
      node, d = pq.pop
      next if d != dist[node]
      neighbors = graph[node]
      next unless neighbors
      neighbors.each do |nbr, weight|
        alt = d + weight
        if alt < dist[nbr]
          dist[nbr] = alt
          pq.push(nbr, alt)
        end
      end
    end

    dist
  end
end
