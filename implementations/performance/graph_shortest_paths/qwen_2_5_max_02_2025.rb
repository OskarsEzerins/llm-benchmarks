class GraphShortestPaths
  class PriorityQueue
    def initialize
      @heap = []
      @index_map = {}
    end

    def push(node, priority)
      return if @index_map.key?(node) && @heap[@index_map[node]][0] <= priority

      if @index_map.key?(node)
        update(node, priority)
      else
        @heap << [priority, node]
        @index_map[node] = @heap.size - 1
        bubble_up(@heap.size - 1)
      end
    end

    def pop
      return nil if @heap.empty?

      swap(0, @heap.size - 1)
      priority, node = @heap.pop
      @index_map.delete(node)

      heapify_down(0) unless @heap.empty?
      [node, priority]
    end

    def empty?
      @heap.empty?
    end

    private

    def update(node, new_priority)
      idx = @index_map[node]
      old_priority, _ = @heap[idx]
      @heap[idx][0] = new_priority

      if new_priority < old_priority
        bubble_up(idx)
      else
        heapify_down(idx)
      end
    end

    def bubble_up(idx)
      parent_idx = (idx - 1) / 2
      while idx > 0 && @heap[parent_idx][0] > @heap[idx][0]
        swap(parent_idx, idx)
        idx = parent_idx
        parent_idx = (idx - 1) / 2
      end
    end

    def heapify_down(idx)
      size = @heap.size
      loop do
        left = 2 * idx + 1
        right = 2 * idx + 2
        smallest = idx

        smallest = left if left < size && @heap[left][0] < @heap[smallest][0]
        smallest = right if right < size && @heap[right][0] < @heap[smallest][0]

        break if smallest == idx

        swap(idx, smallest)
        idx = smallest
      end
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
      @index_map[@heap[i][1]] = i
      @index_map[@heap[j][1]] = j
    end
  end

  def self.compute(graph, source)
    distances = {}
    pq = PriorityQueue.new

    graph.each_key { |node| distances[node] = Float::INFINITY }
    distances[source] = 0
    pq.push(source, 0)

    until pq.empty?
      current, current_distance = pq.pop

      graph[current]&.each do |neighbor, weight|
        new_distance = current_distance + weight
        next unless new_distance < distances[neighbor]

        distances[neighbor] = new_distance
        pq.push(neighbor, new_distance)
      end
    end

    distances
  end
end
