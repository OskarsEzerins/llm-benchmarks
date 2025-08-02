class MinHeap
  def initialize
    @heap = []
    @size = 0
  end

  def empty?
    @size == 0
  end

  def push(priority, value)
    @heap[@size] = [priority, value]
    heapify_up(@size)
    @size += 1
  end

  def pop
    return nil if @size == 0
    
    min = @heap[0]
    @size -= 1
    @heap[0] = @heap[@size]
    heapify_down(0) if @size > 0
    min
  end

  private

  def heapify_up(idx)
    return if idx == 0
    
    parent_idx = (idx - 1) >> 1
    if @heap[idx][0] < @heap[parent_idx][0]
      @heap[idx], @heap[parent_idx] = @heap[parent_idx], @heap[idx]
      heapify_up(parent_idx)
    end
  end

  def heapify_down(idx)
    left = (idx << 1) + 1
    right = (idx << 1) + 2
    smallest = idx

    smallest = left if left < @size && @heap[left][0] < @heap[smallest][0]
    smallest = right if right < @size && @heap[right][0] < @heap[smallest][0]

    if smallest != idx
      @heap[idx], @heap[smallest] = @heap[smallest], @heap[idx]
      heapify_down(smallest)
    end
  end
end

class GraphShortestPaths
  INF = Float::INFINITY

  def self.compute(graph, source)
    distances = Hash.new(INF)
    distances[source] = 0
    pq = MinHeap.new
    pq.push(0, source)

    while !pq.empty?
      current_dist, u = pq.pop
      next if current_dist > distances[u]

      neighbors = graph[u]
      next unless neighbors

      neighbors.each do |v, weight|
        alt = distances[u] + weight
        if alt < distances[v]
          distances[v] = alt
          pq.push(alt, v)
        end
      end
    end

    distances
  end
end