class GraphShortestPaths
  def self.compute(graph, source)
    return {} if graph.empty?

    distances = {}
    visited = {}
    pq = BinaryHeap.new

    distances[source] = 0
    pq.push(0, source)

    while !pq.empty?
      current_dist, u = pq.pop
      next if visited[u]
      visited[u] = true

      neighbors = graph[u]
      next unless neighbors

      neighbors.each do |v, weight|
        next if visited[v]
        alt = current_dist + weight
        if distances[v].nil? || alt < distances[v]
          distances[v] = alt
          pq.push(alt, v)
        end
      end
    end

    distances
  end

  class BinaryHeap
    def initialize
      @heap = []
      @indices = {}
    end

    def empty?
      @heap.empty?
    end

    def push(priority, value)
      if @indices.key?(value)
        old_index = @indices[value]
        old_priority = @heap[old_index][0]
        if priority < old_priority
          @heap[old_index][0] = priority
          bubble_up(old_index)
        end
      else
        index = @heap.size
        @heap << [priority, value]
        @indices[value] = index
        bubble_up(index)
      end
    end

    def pop
      return nil if @heap.empty?

      min = @heap[0]
      last = @heap.pop
      @indices.delete(min[1])

      unless @heap.empty?
        @heap[0] = last
        @indices[last[1]] = 0
        bubble_down(0)
      end

      min
    end

    private

    def bubble_up(index)
      while index > 0
        parent_index = (index - 1) >> 1
        if @heap[index][0] < @heap[parent_index][0]
          swap(index, parent_index)
          index = parent_index
        else
          break
        end
      end
    end

    def bubble_down(index)
      n = @heap.size
      loop do
        smallest = index
        left = (index << 1) + 1
        right = left + 1

        if left < n && @heap[left][0] < @heap[smallest][0]
          smallest = left
        end

        if right < n && @heap[right][0] < @heap[smallest][0]
          smallest = right
        end

        if smallest != index
          swap(index, smallest)
          index = smallest
        else
          break
        end
      end
    end

    def swap(i, j)
      a, b = @heap[i], @heap[j]
      @heap[i] = b
      @heap[j] = a
      @indices[a[1]] = j
      @indices[b[1]] = i
    end
  end
end