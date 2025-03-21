class GraphShortestPaths
  def self.compute(graph, source)
    distances = Array.new(graph.size, Float::INFINITY)
    distances[source] = 0
    priority_queue = BinaryHeap.new
    priority_queue.push([0, source])

    until priority_queue.empty?
      current_distance, node = priority_queue.pop
      next if current_distance > distances[node]

      graph[node].each do |neighbor, weight|
        distance = current_distance + weight
        if distance < distances[neighbor]
          distances[neighbor] = distance
          priority_queue.push([distance, neighbor])
        end
      end
    end

    distances
  end

  class BinaryHeap
    def initialize
      @heap = []
    end

    def push(element)
      @heap << element
      bubble_up(@heap.size - 1)
    end

    def pop
      return nil if @heap.empty?
      swap(0, @heap.size - 1)
      min = @heap.pop
      bubble_down(0)
      min
    end

    def empty?
      @heap.empty?
    end

    private

    def bubble_up(index)
      parent_index = (index - 1) / 2
      return if index == 0 || @heap[parent_index][0] <= @heap[index][0]
      swap(index, parent_index)
      bubble_up(parent_index)
    end

    def bubble_down(index)
      child_index = (2 * index) + 1
      return if child_index >= @heap.size
      child_index += 1 if child_index + 1 < @heap.size && @heap[child_index + 1][0] < @heap[child_index][0]
      return if @heap[index][0] <= @heap[child_index][0]
      swap(index, child_index)
      bubble_down(child_index)
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
    end
  end
end
