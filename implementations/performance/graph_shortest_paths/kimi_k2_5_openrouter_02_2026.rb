class GraphShortestPaths
  def self.compute(graph, source)
    dist = Hash.new(Float::INFINITY)
    dist[source] = 0
    heap = []
    heap_size = 0
    
    heap[0] = [0, source]
    heap_size = 1
    
    while heap_size > 0
      min_dist, u = heap[0]
      heap_size -= 1
      
      if heap_size > 0
        last = heap[heap_size]
        heap[0] = last
        
        i = 0
        loop do
          left = (i << 1) | 1
          right = left + 1
          smallest = i
          
          if left < heap_size && heap[left][0] < heap[smallest][0]
            smallest = left
          end
          if right < heap_size && heap[right][0] < heap[smallest][0]
            smallest = right
          end
          
          break if smallest == i
          
          heap[i], heap[smallest] = heap[smallest], heap[i]
          i = smallest
        end
      end
      
      next if min_dist > dist[u]
      
      neighbors = graph[u]
      if neighbors
        neighbors.each do |v, w|
          alt = min_dist + w
          if alt < dist[v]
            dist[v] = alt
            i = heap_size
            heap_size += 1
            while i > 0
              parent = (i - 1) >> 1
              break if heap[parent][0] <= alt
              heap[i] = heap[parent]
              i = parent
            end
            heap[i] = [alt, v]
          end
        end
      end
    end
    
    dist
  end
end