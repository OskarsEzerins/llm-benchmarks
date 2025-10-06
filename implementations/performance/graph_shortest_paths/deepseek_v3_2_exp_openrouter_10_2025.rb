class GraphShortestPaths
  def self.compute(graph, source)
    n = graph.size
    dist = Array.new(n, Float::INFINITY)
    dist[source] = 0
    
    heap = MinHeap.new(n)
    heap.insert(source, 0)
    
    visited = Array.new(n, false)
    
    while heap.size > 0
      u, d = heap.extract_min
      next if visited[u]
      visited[u] = true
      
      graph[u].each do |v, weight|
        next if visited[v]
        new_dist = d + weight
        if new_dist < dist[v]
          dist[v] = new_dist
          if heap.contains?(v)
            heap.decrease_key(v, new_dist)
          else
            heap.insert(v, new_dist)
          end
        end
      end
    end
    
    dist.map { |d| d.infinite? ? -1 : d }
  end
end

class MinHeap
  def initialize(capacity)
    @heap = []
    @positions = Array.new(capacity, -1)
    @size = 0
  end
  
  def size
    @size
  end
  
  def insert(node, key)
    @heap << [node, key]
    @positions[node] = @size
    @size += 1
    heapify_up(@size - 1)
  end
  
  def extract_min
    return nil if @size == 0
    min = @heap[0]
    @positions[min[0]] = -1
    
    if @size > 1
      @heap[0] = @heap.pop
      @positions[@heap[0][0]] = 0
      @size -= 1
      heapify_down(0)
    else
      @heap.pop
      @size -= 1
    end
    
    min
  end
  
  def decrease_key(node, new_key)
    pos = @positions[node]
    return if pos == -1 || @heap[pos][1] <= new_key
    
    @heap[pos][1] = new_key
    heapify_up(pos)
  end
  
  def contains?(node)
    @positions[node] != -1
  end
  
  private
  
  def heapify_up(index)
    while index > 0
      parent = (index - 1) / 2
      if @heap[index][1] < @heap[parent][1]
        swap(index, parent)
        index = parent
      else
        break
      end
    end
  end
  
  def heapify_down(index)
    loop do
      left = 2 * index + 1
      right = 2 * index + 2
      smallest = index
      
      if left < @size && @heap[left][1] < @heap[smallest][1]
        smallest = left
      end
      
      if right < @size && @heap[right][1] < @heap[smallest][1]
        smallest = right
      end
      
      if smallest != index
        swap(index, smallest)
        index = smallest
      else
        break
      end
    end
  end
  
  def swap(i, j)
    @heap[i], @heap[j] = @heap[j], @heap[i]
    @positions[@heap[i][0]] = i
    @positions[@heap[j][0]] = j
  end
end