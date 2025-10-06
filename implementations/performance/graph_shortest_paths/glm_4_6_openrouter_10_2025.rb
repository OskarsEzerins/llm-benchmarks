class GraphShortestPaths
  class MinHeap
    def initialize
      @heap = []
    end

    def push(item)
      @heap << item
      i = @heap.size - 1
      while i > 0
        parent = (i - 1) >> 1
        break if @heap[parent][0] <= @heap[i][0]
        @heap[parent], @heap[i] = @heap[i], @heap[parent]
        i = parent
      end
    end

    def pop
      return nil if @heap.empty?
      min = @heap[0]
      last = @heap.pop
      if @heap.size > 0
        @heap[0] = last
        i = 0
        size = @heap.size
        loop do
          left = (i << 1) + 1
          right = left + 1
          smallest = i
          if left < size && @heap[left][0] < @heap[smallest][0]
            smallest = left
          end
          if right < size && @heap[right][0] < @heap[smallest][0]
            smallest = right
          end
          break if smallest == i
          @heap[i], @heap[smallest] = @heap[smallest], @heap[i]
          i = smallest
        end
      end
      min
    end

    def empty?
      @heap.empty?
    end
  end

  def self.compute(graph, source)
    distances = {}
    distances.default = Float::INFINITY
    distances[source] = 0
    heap = MinHeap.new
    heap.push([0, source])

    while !heap.empty?
      dist, node = heap.pop
      next if dist != distances[node]

      adj = graph[node]
      next unless adj

      adj.each do |neighbor, weight|
        ndist = dist + weight
        if ndist < distances[neighbor]
          distances[neighbor] = ndist
          heap.push([ndist, neighbor])
        end
      end
    end

    distances
  end
end