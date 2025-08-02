class GraphShortestPaths
  class MinHeap
    def initialize
      @heap = []
      @positions = {}
    end

    def push(node, priority)
      @heap << [node, priority]
      @positions[node] = @heap.size - 1
      sift_up(@heap.size - 1)
    end

    def pop
      return if @heap.empty?

      min = @heap[0]
      @positions.delete(min[0])
      if @heap.size > 1
        @heap[0] = @heap.pop
        @positions[@heap[0][0]] = 0
        sift_down(0)
      else
        @heap.pop
      end

      min[0]
    end

    def decrease_key(node, new_priority)
      index = @positions[node]
      @heap[index][1] = new_priority
      sift_up(index)
    end

    def empty?
      @heap.empty?
    end

    private

    def sift_up(index)
      while index > 0
        parent_index = (index - 1) / 2
        if @heap[index][1] < @heap[parent_index][1]
          swap(index, parent_index)
          index = parent_index
        else
          break
        end
      end
    end

    def sift_down(index)
      loop do
        left_child_index = 2 * index + 1
        right_child_index = 2 * index + 2
        smallest = index

        smallest = left_child_index if left_child_index < @heap.size && @heap[left_child_index][1] < @heap[smallest][1]
        smallest = right_child_index if right_child_index < @heap.size && @heap[right_child_index][1] < @heap[smallest][1]

        if smallest != index
          swap(index, smallest)
          index = smallest
        else
          break
        end
      end
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
      @positions[@heap[i][0]] = i
      @positions[@heap[j][0]] = j
    end
  end

  def self.compute(graph, source)
    distances = Hash.new(Float::INFINITY)
    distances[source] = 0

    min_heap = MinHeap.new
    min_heap.push(source, 0)

    until min_heap.empty?
      current_node = min_heap.pop

      graph[current_node]&.each do |neighbor, weight|
        new_distance = distances[current_node] + weight
        if new_distance < distances[neighbor]
          distances[neighbor] = new_distance
          if min_heap.instance_variable_get(:@positions).key?(neighbor)
            min_heap.decrease_key(neighbor, new_distance)
          else
            min_heap.push(neighbor, new_distance)
          end
        end
      end
    end

    distances
  end
end