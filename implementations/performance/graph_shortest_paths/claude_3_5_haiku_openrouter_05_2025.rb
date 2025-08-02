class GraphShortestPaths
  def self.compute(graph, source)
    Instance.new(graph, source).compute
  end

  class Instance
    def initialize(graph, source)
      @graph = graph
      @source = source
      @distances = Array.new(graph.size, Float::INFINITY)
      @pq = PriorityQueue.new
    end

    def compute
      @distances[@source] = 0
      @pq.push(@source, 0)

      while !@pq.empty?
        current = @pq.pop
        current_dist = @distances[current]

        @graph[current]&.each do |neighbor, weight|
          new_dist = current_dist + weight
          if new_dist < @distances[neighbor]
            @distances[neighbor] = new_dist
            @pq.push(neighbor, new_dist)
          end
        end
      end

      @distances
    end
  end

  class PriorityQueue
    def initialize
      @heap = []
    end

    def push(node, priority)
      @heap << [priority, node]
      bubble_up(@heap.size - 1)
    end

    def pop
      return nil if @heap.empty?

      if @heap.size == 1
        return @heap.pop[1]
      end

      min_node = @heap[0][1]
      @heap[0] = @heap.pop
      bubble_down(0)
      min_node
    end

    def empty?
      @heap.empty?
    end

    private

    def bubble_up(index)
      while index > 0
        parent_idx = (index - 1) >> 1
        break if @heap[parent_idx][0] <= @heap[index][0]

        @heap[parent_idx], @heap[index] = @heap[index], @heap[parent_idx]
        index = parent_idx
      end
    end

    def bubble_down(index)
      heap_size = @heap.size
      loop do
        smallest = index
        left = (index << 1) + 1
        right = left + 1

        smallest = left if left < heap_size && @heap[left][0] < @heap[smallest][0]
        smallest = right if right < heap_size && @heap[right][0] < @heap[smallest][0]

        break if smallest == index

        @heap[index], @heap[smallest] = @heap[smallest], @heap[index]
        index = smallest
      end
    end
  end
end