# graph_shortest_paths.rb

class GraphShortestPaths
  class MinHeap
    def initialize
      @heap = []
    end

    def push(item)
      @heap << item
      sift_up(@heap.size - 1)
    end

    def pop
      return nil if @heap.empty?
      top = @heap[0]
      if @heap.size == 1
        @heap.pop
      else
        @heap[0] = @heap.pop
        sift_down(0)
      end
      top
    end

    def empty?
      @heap.empty?
    end

    private

    def sift_up(idx)
      item = @heap[idx]
      while idx > 0
        parent = (idx - 1) >> 1
        if item[0] < @heap[parent][0]
          @heap[idx] = @heap[parent]
          idx = parent
        else
          break
        end
      end
      @heap[idx] = item
    end

    def sift_down(idx)
      size = @heap.size
      item = @heap[idx]
      loop do
        left = (idx << 1) + 1
        right = left + 1
        smallest = idx

        if left < size && @heap[left][0] < @heap[smallest][0]
          smallest = left
        end
        if right < size && @heap[right][0] < @heap[smallest][0]
          smallest = right
        end

        break if smallest == idx

        @heap[idx] = @heap[smallest]
        idx = smallest
      end
      @heap[idx] = item
    end
  end

  def self.compute(graph, source)
    dist = {}
    heap = MinHeap.new
    heap.push([0, source])
    while !heap.empty?
      d, u = heap.pop
      next if dist.key?(u)
      dist[u] = d
      if neighbors = graph[u]
        neighbors.each do |v, w|
          next if dist.key?(v)
          heap.push([d + w, v])
        end
      end
    end
    dist
  end
end