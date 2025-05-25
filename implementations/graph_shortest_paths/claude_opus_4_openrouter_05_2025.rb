class GraphShortestPaths
  def self.compute(graph, source)
    n = graph.size
    dist = Array.new(n, Float::INFINITY)
    dist[source] = 0
    
    heap = MinHeap.new
    heap.push([0, source])
    
    while !heap.empty?
      d, u = heap.pop
      next if d > dist[u]
      
      graph[u]&.each do |v, w|
        alt = dist[u] + w
        if alt < dist[v]
          dist[v] = alt
          heap.push([alt, v])
        end
      end
    end
    
    dist
  end
  
  class MinHeap
    def initialize
      @heap = []
    end
    
    def push(item)
      @heap << item
      bubble_up(@heap.size - 1)
    end
    
    def pop
      return nil if @heap.empty?
      return @heap.pop if @heap.size == 1
      
      min = @heap[0]
      @heap[0] = @heap.pop
      bubble_down(0)
      min
    end
    
    def empty?
      @heap.empty?
    end
    
    private
    
    def bubble_up(idx)
      while idx > 0
        parent_idx = (idx - 1) >> 1
        break if @heap[parent_idx][0] <= @heap[idx][0]
        
        @heap[parent_idx], @heap[idx] = @heap[idx], @heap[parent_idx]
        idx = parent_idx
      end
    end
    
    def bubble_down(idx)
      size = @heap.size
      while true
        left_idx = (idx << 1) + 1
        right_idx = left_idx + 1
        smallest = idx
        
        smallest = left_idx if left_idx < size && @heap[left_idx][0] < @heap[smallest][0]
        smallest = right_idx if right_idx < size && @heap[right_idx][0] < @heap[smallest][0]
        
        break if smallest == idx
        
        @heap[idx], @heap[smallest] = @heap[smallest], @heap[idx]
        idx = smallest
      end
    end
  end
end