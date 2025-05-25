class BinaryHeap
  def initialize
    @heap = []
  end

  def push(key, priority)
    @heap << [priority, key]
    bubble_up(@heap.size - 1)
  end

  def pop
    return nil if @heap.empty?
    root = @heap[0][1]
    last = @heap.pop
    unless @heap.empty?
      @heap[0] = last
      bubble_down(0)
    end
    root
  end

  def decrease_key(key, priority)
    idx = @heap.index { |p, k| k == key }
    return unless idx
    if priority < @heap[idx][0]
      @heap[idx][0] = priority
      bubble_up(idx)
    end
  end

  def empty?
    @heap.empty?
  end

  private

  def bubble_up(idx)
    parent = (idx - 1) / 2
    while idx > 0 && @heap[parent][0] > @heap[idx][0]
      @heap[parent], @heap[idx] = @heap[idx], @heap[parent]
      idx = parent
      parent = (idx - 1) / 2
    end
  end

  def bubble_down(idx)
    loop do
      min = idx
      left = 2 * idx + 1
      right = 2 * idx + 2

      min = left if left < @heap.size && @heap[left][0] < @heap[min][0]
      min = right if right < @heap.size && @heap[right][0] < @heap[min][0]

      break if min == idx

      @heap[idx], @heap[min] = @heap[min], @heap[idx]
      idx = min
    end
  end
end

class GraphShortestPaths
  INFINITY = Float::INFINITY

  def self.compute(graph, source)
    distances = Hash.new(INFINITY)
    distances[source] = 0
    pq = BinaryHeap.new
    pq.push(source, 0)
    
    until pq.empty?
      u = pq.pop
      next unless u

      graph[u]&.each do |v, weight|
        alt = distances[u] + weight
        if alt < distances[v]
          distances[v] = alt
          pq.push(v, alt)
        end
      end
    end

    distances
  end
end