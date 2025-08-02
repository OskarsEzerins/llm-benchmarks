class GraphShortestPaths
  class PriorityQueue
    def initialize
      @heap = []
    end

    def push(node, priority)
      @heap << [node, priority]
      heapify_up(@heap.size - 1)
    end

    def pop
      return nil if empty?

      root = @heap[0]
      @heap[0] = @heap[@heap.size - 1]
      @heap.pop
      heapify_down(0) unless empty?
      root
    end

    def empty?
      @heap.empty?
    end

    def decrease_key(node, new_priority)
      index = @heap.find_index { |n, _| n == node }
      return if index.nil? || @heap[index][1] <= new_priority

      @heap[index][1] = new_priority
      heapify_up(index)
    end

    private

    def heapify_up(index)
      parent_index = (index - 1) / 2
      return if index <= 0 || @heap[parent_index][1] <= @heap[index][1]

      swap(index, parent_index)
      heapify_up(parent_index)
    end

    def heapify_down(index)
      left_child_index = 2 * index + 1
      right_child_index = 2 * index + 2
      smallest = index

      smallest = left_child_index if left_child_index < @heap.size && @heap[left_child_index][1] < @heap[smallest][1]
      smallest = right_child_index if right_child_index < @heap.size && @heap[right_child_index][1] < @heap[smallest][1]

      return if smallest == index

      swap(index, smallest)
      heapify_down(smallest)
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
    end
  end

  def self.compute(graph, source)
    distances = Hash.new(Float::INFINITY)
    distances[source] = 0

    queue = PriorityQueue.new
    queue.push(source, 0)

    while !queue.empty?
      node, distance = queue.pop
      next if distance > distances[node]

      graph[node].each do |neighbor, weight|
        new_distance = distance + weight
        if new_distance < distances[neighbor]
          distances[neighbor] = new_distance
          queue.push(neighbor, new_distance)
        end
      end
    end

    distances
  end
end