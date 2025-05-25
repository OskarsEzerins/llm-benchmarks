class GraphShortestPaths
  class PriorityQueue
    def initialize
      @heap = []
      @index = {}
    end

    def push(node, distance)
      @heap << [distance, node]
      @index[node] = @heap.size - 1
      heapify_up(@heap.size - 1)
    end

    def pop
      return nil if @heap.empty?
      swap(0, @heap.size - 1)
      min = @heap.pop
      @index.delete(min[1])
      heapify_down(0) unless @heap.empty?
      min
    end

    def decrease_key(node, new_distance)
      idx = @index[node]
      return if idx.nil? || @heap[idx][0] <= new_distance
      @heap[idx][0] = new_distance
      heapify_up(idx)
    end

    def empty?
      @heap.empty?
    end

    private

    def heapify_up(idx)
      while idx > 0
        parent = (idx - 1) / 2
        break if @heap[parent][0] <= @heap[idx][0]
        swap(parent, idx)
        idx = parent
      end
    end

    def heapify_down(idx)
      while true
        left = 2 * idx + 1
        right = 2 * idx + 2
        smallest = idx

        smallest = left if left < @heap.size && @heap[left][0] < @heap[smallest][0]
        smallest = right if right < @heap.size && @heap[right][0] < @heap[smallest][0]
        break if smallest == idx

        swap(smallest, idx)
        idx = smallest
      end
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
      @index[@heap[i][1]] = i
      @index[@heap[j][1]] = j
    end
  end

  def self.compute(graph, source)
    distances = Hash.new(Float::INFINITY)
    distances[source] = 0
    pq = PriorityQueue.new
    pq.push(source, 0)

    until pq.empty?
      current_distance, current_node = pq.pop
      next if current_distance > distances[current_node]

      graph[current_node].each do |neighbor, weight|
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