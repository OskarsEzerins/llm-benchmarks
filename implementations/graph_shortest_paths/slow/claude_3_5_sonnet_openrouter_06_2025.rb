class BinaryHeap
  def initialize
    @heap = []
  end

  def push(priority, value)
    @heap << [priority, value]
    bubble_up(@heap.size - 1)
  end

  def pop
    return nil if @heap.empty?
    min = @heap[0]
    @heap[0] = @heap.pop
    bubble_down(0) unless @heap.empty?
    min
  end

  def empty?
    @heap.empty?
  end

  private

  def bubble_up(index)
    parent = (index - 1) / 2
    while index > 0 && @heap[parent][0] > @heap[index][0]
      @heap[parent], @heap[index] = @heap[index], @heap[parent]
      index = parent
      parent = (index - 1) / 2
    end
  end

  def bubble_down(index)
    loop do
      min = index
      left = 2 * index + 1
      right = 2 * index + 2

      min = left if left < @heap.size && @heap[left][0] < @heap[min][0]
      min = right if right < @heap.size && @heap[right][0] < @heap[min][0]

      break if min == index
      
      @heap[index], @heap[min] = @heap[min], @heap[index]
      index = min
    end
  end
end

class GraphShortestPaths
  INFINITY = Float::INFINITY

  def self.compute(graph, source)
    distances = {}
    graph.keys.each { |node| distances[node] = INFINITY }
    distances[source] = 0

    pq = BinaryHeap.new
    pq.push(0, source)

    until pq.empty?
      dist, current = pq.pop
      next if dist > distances[current]

      graph[current]&.each do |neighbor, weight|
        new_dist = dist + weight
        if new_dist < distances[neighbor]
          distances[neighbor] = new_dist
          pq.push(new_dist, neighbor)
        end
      end
    end

    distances
  end
end