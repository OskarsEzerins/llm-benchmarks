class GraphShortestPaths
  class BinaryHeap
    def initialize
      @heap = []
      @positions = {}
    end

    def empty?
      @heap.empty?
    end

    def insert(node, priority)
      @heap << [priority, node]
      @positions[node] = @heap.size - 1
      bubble_up(@heap.size - 1)
    end

    def extract_min
      return nil if @heap.empty?

      min_priority, min_node = @heap[0]
      last_priority, last_node = @heap.pop
      @positions.delete(min_node)

      unless @heap.empty?
        @heap[0] = [last_priority, last_node]
        @positions[last_node] = 0
        bubble_down(0)
      end

      [min_node, min_priority]
    end

    def decrease_key(node, new_priority)
      return unless @positions.key?(node)

      position = @positions[node]
      if new_priority < @heap[position][0]
        @heap[position][0] = new_priority
        bubble_up(position)
      end
    end

    private

    def bubble_up(index)
      parent_index = (index - 1) / 2

      if index > 0 && @heap[index][0] < @heap[parent_index][0]
        swap(index, parent_index)
        bubble_up(parent_index)
      end
    end

    def bubble_down(index)
      left = 2 * index + 1
      right = 2 * index + 2
      smallest = index

      smallest = left if left < @heap.size && @heap[left][0] < @heap[smallest][0]
      smallest = right if right < @heap.size && @heap[right][0] < @heap[smallest][0]

      if smallest != index
        swap(index, smallest)
        bubble_down(smallest)
      end
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
      @positions[@heap[i][1]] = i
      @positions[@heap[j][1]] = j
    end
  end

  def self.compute(graph, source)
    distances = {}
    pq = BinaryHeap.new

    graph.each_key do |node|
      if node == source
        distances[node] = 0
        pq.insert(node, 0)
      else
        distances[node] = Float::INFINITY
        pq.insert(node, Float::INFINITY)
      end
    end

    until pq.empty?
      node, dist = pq.extract_min

      graph[node]&.each do |neighbor, weight|
        next unless distances.key?(neighbor)

        new_dist = dist + weight
        if new_dist < distances[neighbor]
          distances[neighbor] = new_dist
          pq.decrease_key(neighbor, new_dist)
        end
      end
    end

    distances
  end
end
