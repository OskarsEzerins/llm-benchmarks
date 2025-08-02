class GraphShortestPaths
  def self.compute(graph, source)
    num_nodes = graph.keys.max + 1
    distances = Array.new(num_nodes, Float::INFINITY)
    distances[source] = 0

    priority_queue = PriorityQueue.new
    priority_queue.insert(source, 0)

    until priority_queue.empty?
      node, node_dist = priority_queue.extract_min
      next if node_dist > distances[node]

      graph.fetch(node, []).each do |neighbor, weight|
        new_distance = distances[node] + weight
        if new_distance < distances[neighbor]
          distances[neighbor] = new_distance
          priority_queue.insert(neighbor, new_distance)
        end
      end
    end

    distances
  end

  class PriorityQueue
    def initialize
      @heap = []
      @node_indices = {}
    end

    def insert(node, priority)
      if @node_indices.key?(node)
        decrease_priority(node, priority)
      else
        @heap << [node, priority]
        @node_indices[node] = @heap.size - 1
        heapify_up(@heap.size - 1)
      end
    end

    def extract_min
      return nil if empty?

      min_node, min_priority = @heap[0]
      last_node, last_priority = @heap.pop
      @node_indices.delete(min_node)

      if !empty?
        @heap[0] = [last_node, last_priority]
        @node_indices[last_node] = 0
        heapify_down(0)
      end

      [min_node, min_priority]
    end

    def empty?
      @heap.empty?
    end

    private

    def decrease_priority(node, new_priority)
      index = @node_indices[node]
      return if index.nil? || @heap[index][1] <= new_priority

      @heap[index][1] = new_priority
      heapify_up(index)
    end

    def heapify_up(index)
      parent_index = (index - 1) / 2
      return if parent_index < 0 || @heap[index][1] >= @heap[parent_index][1]

      swap(index, parent_index)
      heapify_up(parent_index)
    end

    def heapify_down(index)
      left_child_index = 2 * index + 1
      right_child_index = 2 * index + 2
      smallest = index

      if left_child_index < @heap.size && @heap[left_child_index][1] < @heap[smallest][1]
        smallest = left_child_index
      end

      if right_child_index < @heap.size && @heap[right_child_index][1] < @heap[smallest][1]
        smallest = right_child_index
      end

      return if smallest == index

      swap(index, smallest)
      heapify_down(smallest)
    end

    def swap(index1, index2)
      @heap[index1], @heap[index2] = @heap[index2], @heap[index1]
      @node_indices[@heap[index1][0]] = index1
      @node_indices[@heap[index2][0]] = index2
    end
  end
end
