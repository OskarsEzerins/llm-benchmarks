class GraphShortestPaths
  # Binary Min-Heap optimized for Dijkstra's algorithm
  # Uses a flat array for storage to minimize object creation overhead.
  # Elements are stored as [distance, node] pairs in contiguous memory.
  class MinHeap
    def initialize
      @data = []
    end

    # Pushes a new [distance, node] pair onto the heap
    def push(distance, node)
      data = @data
      data << distance
      data << node
      
      # Bubble up
      i = (data.size >> 1) - 1 # Index of the last block (size/2 - 1)
      
      while i > 0
        parent = (i - 1) >> 1
        i_dist = data[i << 1]
        parent_dist = data[parent << 1]
        
        if i_dist < parent_dist
          # Swap block i and parent
          i_base = i << 1
          p_base = parent << 1
          
          # Swap distance
          data[i_base], data[p_base] = data[p_base], data[i_base]
          # Swap node
          data[i_base + 1], data[p_base + 1] = data[p_base + 1], data[i_base + 1]
          
          i = parent
        else
          break
        end
      end
    end

    # Pops the [distance, node] pair with the smallest distance
    def pop
      data = @data
      return nil if data.empty?

      # Root elements
      d = data[0]
      n = data[1]
      
      # Move last block to root
      last_dist = data.pop
      last_node = data.pop
      
      if data.empty?
        # If the heap is now empty, we just removed the last element
        # But if we popped distance/node above, and array is empty, we are done.
        # However, `last_dist` and `last_node` are assigned *after* pop.
        # If data was size 2 (1 element), data.pop gets node, data.pop gets dist.
        # data becomes empty.
        return [d, n]
      end
      
      data[0] = last_dist
      data[1] = last_node
      
      # Heapify down
      size = data.size >> 1
      i = 0
      
      loop do
        left = (i << 1) + 1
        right = left + 1
        smallest = i
        
        # Compare distances (at index*2)
        base_smallest = smallest << 1
        d_smallest = data[base_smallest]
        
        if left < size
          base_left = left << 1
          if data[base_left] < d_smallest
            smallest = left
            d_smallest = data[base_left]
            base_smallest = base_left
          end
        end
        
        if right < size
          base_right = right << 1
          if data[base_right] < d_smallest
            smallest = right
            base_smallest = base_right
          end
        end
        
        if smallest != i
          # Swap blocks i and smallest
          base_i = i << 1
          
          # Swap distance
          data[base_i], data[base_smallest] = data[base_smallest], data[base_i]
          # Swap node
          data[base_i + 1], data[base_smallest + 1] = data[base_smallest + 1], data[base_i + 1]
          
          i = smallest
        else
          break
        end
      end
      
      [d, n]
    end
    
    def empty?
      @data.empty?
    end
  end

  def self.compute(graph, source)
    # Using a Hash with default value Float::INFINITY allows efficient initialization
    # and handles nodes not explicitly in the distance map yet.
    distances = Hash.new(Float::INFINITY)
    distances[source] = 0
    
    # Priority Queue
    pq = MinHeap.new
    pq.push(0, source)
    
    # Dijkstra's Algorithm
    until pq.empty?
      d, u = pq.pop
      
      # Optimization: If we extracted a distance larger than currently known,
      # this entry is stale (lazy deletion). Skip it.
      if d > distances[u]
        next
      end
      
      # Iterate neighbors
      neighbors = graph[u]
      next unless neighbors
      
      neighbors.each do |v, weight|
        new_dist = d + weight
        
        if new_dist < distances[v]
          distances[v] = new_dist
          pq.push(new_dist, v)
        end
      end
    end
    
    distances
  end
end