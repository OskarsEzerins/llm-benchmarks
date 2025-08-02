class GraphShortestPaths
  class BinaryHeap
    def initialize
      @heap = []
    end
    
    def empty?
      @heap.empty?
    end
    
    def push(priority, node)
      @heap << [priority, node]
      idx = @heap.size - 1
      parent_idx = (idx - 1) / 2
      
      while idx > 0 && @heap[parent_idx][0] > @heap[idx][0]
        @heap[parent_idx], @heap[idx] = @heap[idx], @heap[parent_idx]
        idx = parent_idx
        parent_idx = (idx - 1) / 2
      end
    end
    
    def pop
      return nil if @heap.empty?
      
      min = @heap[0]
      last = @heap.pop
      
      unless @heap.empty?
        @heap[0] = last
        
        idx = 0
        size = @heap.size
        
        loop do
          smallest = idx
          left = 2 * idx + 1
          right = 2 * idx + 2
          
          smallest = left if left < size && @heap[left][0] < @heap[smallest][0]
          smallest = right if right < size && @heap[right][0] < @heap[smallest][0]
          
          break if smallest == idx
          
          @heap[idx], @heap[smallest] = @heap[smallest], @heap[idx]
          idx = smallest
        end
      end
      
      min
    end
  end
  
  def self.compute(graph, source)
    dist = {}
    graph.each_key { |node| dist[node] = Float::INFINITY }
    dist[source] = 0
    
    processed = {}
    
    heap = BinaryHeap.new
    heap.push(0, source)
    
    until heap.empty?
      current_dist, u = heap.pop
      
      next if processed[u]
      processed[u] = true
      
      (graph[u] || []).each do |v, weight|
        next if processed[v]
        
        dist[v] ||= Float::INFINITY
        new_dist = current_dist + weight
        
        if new_dist < dist[v]
          dist[v] = new_dist
          heap.push(new_dist, v)
        end
      end
    end
    
    dist
  end
end