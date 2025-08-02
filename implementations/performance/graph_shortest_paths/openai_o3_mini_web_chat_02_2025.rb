class GraphShortestPaths
  def self.compute(graph, source)
    dist = {}
    graph.each_key { |node| dist[node] = Float::INFINITY }
    dist[source] = 0
    pq = PriorityQueue.new
    pq.push(source, 0)
    until pq.empty?
      current, current_dist = pq.pop
      next if current_dist > dist[current]
      if graph[current]
        graph[current].each do |neighbor, weight|
          new_dist = current_dist + weight
          if new_dist < dist.fetch(neighbor, Float::INFINITY)
            dist[neighbor] = new_dist
            pq.push(neighbor, new_dist)
          end
        end
      end
    end
    dist
  end
end

class PriorityQueue
  def initialize
    @heap = []
  end

  def empty?
    @heap.empty?
  end

  def push(item, priority)
    @heap << [priority, item]
    heapify_up(@heap.size - 1)
  end

  def pop
    return nil if @heap.empty?
    min = @heap[0]
    last = @heap.pop
    unless @heap.empty?
      @heap[0] = last
      heapify_down(0)
    end
    [min[1], min[0]]
  end

  private

  def heapify_up(idx)
    parent = (idx - 1) >> 1
    while idx > 0 && @heap[idx][0] < @heap[parent][0]
      @heap[idx], @heap[parent] = @heap[parent], @heap[idx]
      idx = parent
      parent = (idx - 1) >> 1
    end
  end

  def heapify_down(idx)
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
