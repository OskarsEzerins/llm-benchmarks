class GraphShortestPaths
  class PriorityQueue
    def initialize
      @heap = []
      @indices = {}
    end

    def insert(node, priority)
      return if @indices[node] # Node is already in the queue

      @heap << [priority, node]
      @indices[node] = @heap.size - 1
      bubble_up(@heap.size - 1)
    end

    def extract_min
      return nil if @heap.empty?

      min_node = @heap[0][1]
      swap(0, @heap.size - 1)
      @heap.pop
      @indices.delete(min_node)
      bubble_down(0)
      min_node
    end

    def decrease_key(node, new_priority)
      return unless @indices[node]

      index = @indices[node]
      old_priority = @heap[index][0]
      return if new_priority >= old_priority

      @heap[index][0] = new_priority
      bubble_up(index)
    end

    def empty?
      @heap.empty?
    end

    private

    def bubble_up(index)
      while index > 0
        parent_index = (index - 1) / 2
        break if @heap[parent_index][0] <= @heap[index][0]

        swap(index, parent_index)
        index = parent_index
      end
    end

    def bubble_down(index)
      size = @heap.size
      loop do
        left_index = 2 * index + 1
        right_index = 2 * index + 2
        smallest_index = index

        if left_index < size && @heap[left_index][0] < @heap[smallest_index][0]
          smallest_index = left_index
        end

        if right_index < size && @heap[right_index][0] < @heap[smallest_index][0]
          smallest_index = right_index
        end

        break if smallest_index == index

        swap(index, smallest_index)
        index = smallest_index
      end
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
      @indices[@heap[i][1]] = i
      @indices[@heap[j][1]] = j
    end
  end

  def self.compute(graph, source)
    distances = Hash.new(Float::INFINITY)
    distances[source] = 0
    pq = PriorityQueue.new
    pq.insert(source, 0)

    until pq.empty?
      current = pq.extract_min
      current_distance = distances[current]

      graph[current].each do |neighbor, weight|
        distance = current_distance + weight
        if distance < distances[neighbor]
          distances[neighbor] = distance
          pq.decrease_key(neighbor, distance)
        end
      end
    end

    distances
  end
end