class GraphShortestPaths
  class MinHeap
    attr_reader :last_key

    def initialize
      @keys = []
      @values = []
      @size = 0
      @last_key = nil
    end

    def push(key, value)
      idx = @size
      @size = idx + 1
      keys = @keys
      values = @values
      keys[idx] = key
      values[idx] = value
      sift_up(idx)
    end

    def pop
      size = @size
      return nil if size == 0
      keys = @keys
      values = @values
      root_key = keys[0]
      root_value = values[0]
      last_index = size - 1
      last_key = keys[last_index]
      last_value = values[last_index]
      keys.pop
      values.pop
      if last_index > 0
        keys[0] = last_key
        values[0] = last_value
        @size = last_index
        sift_down(0)
      else
        @size = 0
      end
      @last_key = root_key
      root_value
    end

    private

    def sift_up(index)
      keys = @keys
      values = @values
      key = keys[index]
      value = values[index]
      while index > 0
        parent = (index - 1) >> 1
        parent_key = keys[parent]
        break if key >= parent_key
        keys[index] = parent_key
        values[index] = values[parent]
        index = parent
      end
      keys[index] = key
      values[index] = value
    end

    def sift_down(index)
      size = @size
      keys = @keys
      values = @values
      key = keys[index]
      value = values[index]
      half = size >> 1
      while index < half
        left = (index << 1) + 1
        right = left + 1
        best = left
        best_key = keys[left]
        if right < size
          right_key = keys[right]
          if right_key < best_key
            best = right
            best_key = right_key
          end
        end
        break if key <= best_key
        keys[index] = best_key
        values[index] = values[best]
        index = best
      end
      keys[index] = key
      values[index] = value
    end
  end

  def self.compute(graph, source)
    distances = {}
    heap = MinHeap.new
    distances[source] = 0
    heap.push(0, source)
    adjacency = graph
    while (node = heap.pop)
      current_distance = heap.last_key
      recorded_distance = distances[node]
      next unless recorded_distance == current_distance
      neighbors = adjacency[node]
      next if neighbors.nil?
      length = neighbors.length
      next if length == 0
      i = 0
      while i < length
        edge = neighbors[i]
        neighbor = edge[0]
        new_distance = current_distance + edge[1]
        existing = distances[neighbor]
        if existing.nil? || new_distance < existing
          distances[neighbor] = new_distance
          heap.push(new_distance, neighbor)
        end
        i += 1
      end
    end
    distances
  end
end