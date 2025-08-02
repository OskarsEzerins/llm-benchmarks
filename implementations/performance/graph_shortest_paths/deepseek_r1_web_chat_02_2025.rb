class GraphShortestPaths
  def self.compute(graph, source)
    distances = Hash.new(Float::INFINITY)
    distances[source] = 0
    pq = PriorityQueue.new
    pq.push(0, source)

    until pq.empty?
      current_distance, current_node = pq.pop
      next if current_distance > distances[current_node]

      graph[current_node].each do |neighbor, weight|
        distance = current_distance + weight
        if distance < distances[neighbor]
          distances[neighbor] = distance
          pq.push(distance, neighbor)
        end
      end
    end

    distances
  end
end

class PriorityQueue
  def initialize
    @heap = []
  end

  def push(distance, node)
    @heap << [distance, node]
    current_index = @heap.size - 1
    while current_index > 0
      parent_index = (current_index - 1) / 2
      if @heap[parent_index][0] > @heap[current_index][0]
        @heap[parent_index], @heap[current_index] = @heap[current_index], @heap[parent_index]
        current_index = parent_index
      else
        break
      end
    end
  end

  def pop
    return nil if @heap.empty?
    min = @heap[0]
    last = @heap.pop
    unless @heap.empty?
      @heap[0] = last
      current_index = 0
      loop do
        left_child = 2 * current_index + 1
        right_child = 2 * current_index + 2
        smallest = current_index
        if left_child < @heap.size && @heap[left_child][0] < @heap[smallest][0]
          smallest = left_child
        end
        if right_child < @heap.size && @heap[right_child][0] < @heap[smallest][0]
          smallest = right_child
        end
        break if smallest == current_index
        @heap[current_index], @heap[smallest] = @heap[smallest], @heap[current_index]
        current_index = smallest
      end
    end
    min
  end

  def empty?
    @heap.empty?
  end
end
