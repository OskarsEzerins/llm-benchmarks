class GraphShortestPaths
  class BinaryHeap
    def initialize
      @nodes = []
    end

    def push(node, priority)
      @nodes << [node, priority]
      sift_up(@nodes.size - 1)
    end

    def pop
      return nil if @nodes.empty?

      result = @nodes[0]
      if @nodes.size > 1
        @nodes[0] = @nodes.pop
        sift_down(0)
      else
        @nodes.pop
      end
      result
    end

    def decrease_key(node, new_priority)
      index = @nodes.index { |n, _| n == node }
      return unless index

      if new_priority < @nodes[index][1]
        @nodes[index][1] = new_priority
        sift_up(index)
      end
    end

    def has_node?(node)
      @nodes.any? { |n, _| n == node }
    end

    def empty?
      @nodes.empty?
    end

    private

    def sift_up(index)
      parent = (index - 1) / 2

      if parent >= 0 && @nodes[index][1] < @nodes[parent][1]
        @nodes[parent], @nodes[index] = @nodes[index], @nodes[parent]
        sift_up(parent)
      end
    end

    def sift_down(index)
      min_index = index
      left = 2 * index + 1
      right = 2 * index + 2

      if left < @nodes.size && @nodes[left][1] < @nodes[min_index][1]
        min_index = left
      end

      if right < @nodes.size && @nodes[right][1] < @nodes[min_index][1]
        min_index = right
      end

      if min_index != index
        @nodes[index], @nodes[min_index] = @nodes[min_index], @nodes[index]
        sift_down(min_index)
      end
    end
  end

  def self.compute(graph, source)
    distances = {}
    graph.each_key { |node| distances[node] = Float::INFINITY }
    distances[source] = 0

    pq = BinaryHeap.new
    pq.push(source, 0)

    until pq.empty?
      current, current_dist = pq.pop
      next if current_dist > distances[current]

      neighbors = graph[current] || []
      neighbors.each do |neighbor, weight|
        distance = current_dist + weight

        if distance < distances[neighbor]
          distances[neighbor] = distance
          pq.push(neighbor, distance)
        end
      end
    end

    distances
  end
end
