class GraphShortestPaths
  def self.compute(graph, source)
    dist = Hash.new(Float::INFINITY)
    dist[source] = 0
    heap = MinHeap.new
    heap.push([0, source])
    until heap.empty?
      d, node = heap.pop
      next if d > dist[node]
      (graph[node] || []).each do |neighbor, weight|
        new_d = d + weight
        if new_d < dist[neighbor]
          dist[neighbor] = new_d
          heap.push([new_d, neighbor])
        end
      end
    end
    dist
  end

  class MinHeap
    def initialize
      @heap = []
    end

    def push(element)
      @heap << element
      sift_up(@heap.size - 1)
    end

    def pop
      return nil if @heap.empty?
      min = @heap[0]
      last = @heap.pop
      unless @heap.empty?
        @heap[0] = last
        sift_down(0)
      end
      min
    end

    def empty?
      @heap.empty?
    end

    private

    def sift_up(idx)
      while idx.positive?
        parent = (idx - 1) >> 1
        break if @heap[idx][0] >= @heap[parent][0]
        @heap[idx], @heap[parent] = @heap[parent], @heap[idx]
        idx = parent
      end
    end

    def sift_down(idx)
      size = @heap.size
      loop do
        left = (idx << 1) + 1
        right = left + 1
        smallest = idx
        smallest = left if left < size && @heap[left][0] < @heap[smallest][0]
        smallest = right if right < size && @heap[right][0] < @heap[smallest][0]
        break if smallest == idx
        @heap[idx], @heap[smallest] = @heap[smallest], @heap[idx]
        idx = smallest
      end
    end
  end
end
