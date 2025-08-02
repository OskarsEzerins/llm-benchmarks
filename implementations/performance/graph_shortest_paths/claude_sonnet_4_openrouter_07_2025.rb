class GraphShortestPaths
  class BinaryHeap
    def initialize
      @heap = []
      @size = 0
    end

    def empty?
      @size == 0
    end

    def push(priority, value)
      @heap[@size] = [priority, value]
      bubble_up(@size)
      @size += 1
    end

    def pop
      return nil if @size == 0
      
      min = @heap[0]
      @size -= 1
      if @size > 0
        @heap[0] = @heap[@size]
        bubble_down(0)
      end
      min
    end

    private

    def bubble_up(index)
      while index > 0
        parent = (index - 1) >> 1
        break if @heap[parent][0] <= @heap[index][0]
        @heap[parent], @heap[index] = @heap[index], @heap[parent]
        index = parent
      end
    end

    def bubble_down(index)
      while true
        left = (index << 1) + 1
        right = left + 1
        smallest = index

        if left < @size && @heap[left][0] < @heap[smallest][0]
          smallest = left
        end

        if right < @size && @heap[right][0] < @heap[smallest][0]
          smallest = right
        end

        break if smallest == index

        @heap[index], @heap[smallest] = @heap[smallest], @heap[index]
        index = smallest
      end
    end
  end

  def self.compute(graph, source)
    distances = {}
    heap = BinaryHeap.new
    
    heap.push(0, source)
    distances[source] = 0
    
    while !heap.empty?
      current_dist, node = heap.pop
      
      next if distances.key?(node) && distances[node] < current_dist
      
      neighbors = graph[node]
      next unless neighbors
      
      neighbors.each do |neighbor, weight|
        new_dist = current_dist + weight
        
        if !distances.key?(neighbor) || new_dist < distances[neighbor]
          distances[neighbor] = new_dist
          heap.push(new_dist, neighbor)
        end
      end
    end
    
    distances
  end
end