# graph_shortest_paths.rb
class GraphShortestPaths
  INFINITY = 1.0/0

  def self.compute(graph, source)
    dist = Hash.new(INFINITY)
    dist[source] = 0
    visited = {}
    queue = MinHeap.new
    queue.push([0, source])
    while queue.size > 0
      current_dist, node = queue.pop
      next if visited[node]
      visited[node] = true
      break unless graph[node]
      graph[node].each do |(nbr, weight)|
        new_dist = current_dist + weight
        if new_dist < dist[nbr]
          dist[nbr] = new_dist
          queue.push([new_dist, nbr])
        end
      end
    end
    dist
  end

  class MinHeap
    attr_reader :size

    def initialize
      @heap = []
      @size = 0
    end

    def push(val)
      @heap << val
      @size += 1
      up_heap(@size - 1)
    end

    def pop
      return nil if @size == 0
      swap(0, @size - 1)
      top = @heap.pop
      @size -= 1
      down_heap(0) if @size > 0
      top
    end

    private

    def up_heap(idx)
      return if idx <= 0
      parent = (idx - 1) >> 1
      if @heap[idx].first < @heap[parent].first
        swap(idx, parent)
        up_heap(parent)
      end
    end

    def down_heap(idx)
      left = (idx << 1) + 1
      right = left + 1
      smallest = idx
      smallest = left if left < @size && @heap[left].first < @heap[smallest].first
      smallest = right if right < @size && @heap[right].first < @heap[smallest].first
      if smallest != idx
        swap(idx, smallest)
        down_heap(smallest)
      end
    end

    def swap(i, j)
      @heap[i], @heap[j] = @heap[j], @heap[i]
    end
  end
end
