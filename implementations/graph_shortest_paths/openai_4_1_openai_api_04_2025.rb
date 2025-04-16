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
      swap(0, @heap.size - 1)
      min = @heap.pop
      sift_down(0)
      min
    end

    def empty?
      @heap.empty?
    end

    private

    def sift_up(idx)
      while idx > 0
        parent = (idx - 1) >> 1
        break if @heap[parent][0] <= @heap[idx][0]
        swap(parent, idx)
        idx = parent
      end
    end

    def sift_down(idx)
      n = @heap.size
      while (child = (idx << 1) + 1) < n
        r = child + 1
        min_idx = (r < n && @heap[r][0] < @heap[child][0]) ? r : child
        break if @heap[idx][0] <= @heap[min_idx][0]
        swap(idx, min_idx)
        idx = min_idx
      end
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
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
      neighbors = graph[u]
      if neighbors
        neighbors.each do |v, w|
          next if dist.key?(v)
          heap.push([d + w, v])
        end
      end
    end
    dist
  end
end
