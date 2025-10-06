class GraphShortestPaths
  def self.compute(graph, source)
    return {} if graph.empty?

    distances = Hash.new(Float::INFINITY)
    distances[source] = 0

    pq = MinHeap.new
    pq.push(source, 0)

    visited = {}

    while !pq.empty?
      current_node, current_dist = pq.pop
      next if visited[current_node]
      visited[current_node] = true

      neighbors = graph[current_node]
      next unless neighbors

      neighbors.each do |neighbor, weight|
        next if visited[neighbor]
        new_dist = current_dist + weight
        if new_dist < distances[neighbor]
          distances[neighbor] = new_dist
          pq.push(neighbor, new_dist)
        end
      end
    end

    distances
  end

  class MinHeap
    def initialize
      @heap = []
      @indices = {}
    end

    def push(node, priority)
      if @indices.key?(node)
        idx = @indices[node]
        old_priority = @heap[idx][0]
        if priority < old_priority
          @heap[idx][0] = priority
          bubble_up(idx)
        end
      else
        idx = @heap.size
        @heap << [priority, node]
        @indices[node] = idx
        bubble_up(idx)
      end
    end

    def pop
      return nil if @heap.empty?

      priority, node = @heap[0]
      last = @heap.pop
      @indices.delete(node)

      unless @heap.empty?
        @heap[0] = last
        @indices[last[1]] = 0
        bubble_down(0)
      end

      [node, priority]
    end

    def empty?
      @heap.empty?
    end

    private

    def bubble_up(idx)
      while idx > 0
        parent_idx = (idx - 1) >> 1
        if @heap[idx][0] < @heap[parent_idx][0]
          swap(idx, parent_idx)
          idx = parent_idx
        else
          break
        end
      end
    end

    def bubble_down(idx)
      n = @heap.size
      while true
        smallest = idx
        left = (idx << 1) + 1
        right = (idx << 1) + 2

        if left < n && @heap[left][0] < @heap[smallest][0]
          smallest = left
        end
        if right < n && @heap[right][0] < @heap[smallest][0]
          smallest = right
        end

        if smallest != idx
          swap(idx, smallest)
          idx = smallest
        else
          break
        end
      end
    end

    def swap(i, j)
      node_i = @heap[i][1]
      node_j = @heap[j][1]
      @indices[node_i] = j
      @indices[node_j] = i
      @heap[i], @heap[j] = @heap[j], @heap[i]
    end
  end
end