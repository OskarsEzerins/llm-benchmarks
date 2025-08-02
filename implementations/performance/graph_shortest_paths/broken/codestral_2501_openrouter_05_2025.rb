class GraphShortestPaths
  class BinaryHeap
    def initialize
      @heap = []
    end

    def push(node, priority)
      @heap.push([node, priority])
      bubble_up(@heap.size - 1)
    end

    def pop
      return nil if @heap.empty?
      swap(0, @heap.size - 1)
      min = @heap.pop
      bubble_down(0)
      min
    end

    private

    def bubble_up(index)
      parent_index = (index - 1) / 2
      return if index == 0 || @heap[parent_index][1] <= @heap[index][1]
      swap(index, parent_index)
      bubble_up(parent_index)
    end

    def bubble_down(index)
      child_index = 2 * index + 1
      return if child_index >= @heap.size
      child_index += 1 if child_index + 1 < @heap.size && @heap[child_index][1] > @heap[child_index + 1][1]
      return if @heap[index][1] <= @heap[child_index][1]
      swap(index, child_index)
      bubble_down(child_index)
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
    end
  end

  def self.compute(graph, source)
    distances = Hash.new(Float::INFINITY)
    distances[source] = 0
    pq = BinaryHeap.new
    pq.push(source, 0)

    until pq.empty?
      node, current_distance = pq.pop
      next if current_distance > distances[node]

      graph[node].each do |neighbor, weight|
        distance = current_distance + weight
        if distance < distances[neighbor]
          distances[neighbor] = distance
          pq.push(neighbor, distance)
        end
      end
    end

    distances
  end
end