class GraphShortestPaths
  class MinHeap
    def initialize
      @nodes = []
      @keys = []
      @result = [nil, nil]
    end

    def push(node, key)
      nodes = @nodes
      keys = @keys
      idx = nodes.length
      nodes << node
      keys << key
      while idx > 0
        parent = (idx - 1) >> 1
        parent_key = keys[parent]
        break if key >= parent_key
        nodes[idx] = nodes[parent]
        keys[idx] = parent_key
        idx = parent
      end
      nodes[idx] = node
      keys[idx] = key
    end

    def pop
      nodes = @nodes
      return nil if nodes.empty?
      keys = @keys
      top_node = nodes[0]
      top_key = keys[0]
      last_index = nodes.length - 1
      if last_index == 0
        nodes.pop
        keys.pop
      else
        nodes[0] = nodes.pop
        keys[0] = keys.pop
        sift_down
      end
      result = @result
      result[0] = top_node
      result[1] = top_key
      result
    end

    private

    def sift_down
      nodes = @nodes
      keys = @keys
      idx = 0
      len = nodes.length
      node = nodes[0]
      key = keys[0]
      half = len >> 1
      while idx < half
        left = (idx << 1) + 1
        right = left + 1
        smallest = left
        child_key = keys[left]
        if right < len
          right_key = keys[right]
          if right_key < child_key
            smallest = right
            child_key = right_key
          end
        end
        break if key <= child_key
        nodes[idx] = nodes[smallest]
        keys[idx] = child_key
        idx = smallest
      end
      nodes[idx] = node
      keys[idx] = key
    end
  end

  def self.compute(graph, source)
    dist = {}
    heap = MinHeap.new
    dist[source] = 0
    heap.push(source, 0)
    while (entry = heap.pop)
      node = entry[0]
      d = entry[1]
      current = dist[node]
      next unless current && d == current
      neighbors = graph[node]
      next unless neighbors
      i = 0
      len = neighbors.length
      while i < len
        pair = neighbors[i]
        neighbor = pair[0]
        weight = pair[1]
        new_dist = d + weight
        old_dist = dist[neighbor]
        if !old_dist || new_dist < old_dist
          dist[neighbor] = new_dist
          heap.push(neighbor, new_dist)
        end
        i += 1
      end
    end
    dist
  end
end