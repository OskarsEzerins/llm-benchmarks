class MinHeap
  def initialize
    @heap = []
    @positions = {}
  end

  def empty?
    @heap.empty?
  end

  def push(node, priority)
    @heap << [node, priority]
    @positions[node] = @heap.size - 1
    heapify_up(@heap.size - 1)
  end

  def extract_min
    return nil if @heap.empty?
    
    min_node, min_priority = @heap[0]
    last_node, last_priority = @heap.pop
    
    if @heap.size > 0
      @heap[0] = [last_node, last_priority]
      @positions[last_node] = 0
      heapify_down(0)
    end
    
    @positions.delete(min_node)
    [min_node, min_priority]
  end

  def decrease_key(node, new_priority)
    return unless @positions.key?(node)
    
    pos = @positions[node]
    if new_priority < @heap[pos][1]
      @heap[pos][1] = new_priority
      heapify_up(pos)
    end
  end

  def contains?(node)
    @positions.key?(node)
  end

  private

  def heapify_up(index)
    parent = (index - 1) / 2
    
    if index > 0 && @heap[parent][1] > @heap[index][1]
      swap(parent, index)
      heapify_up(parent)
    end
  end

  def heapify_down(index)
    smallest = index
    left = 2 * index + 1
    right = 2 * index + 2
    
    smallest = left if left < @heap.size && @heap[left][1] < @heap[smallest][1]
    smallest = right if right < @heap.size && @heap[right][1] < @heap[smallest][1]
    
    if smallest != index
      swap(index, smallest)
      heapify_down(smallest)
    end
  end

  def swap(i, j)
    @heap[i], @heap[j] = @heap[j], @heap[i]
    @positions[@heap[i][0]] = i
    @positions[@heap[j][0]] = j
  end
end

class GraphShortestPaths
  def self.compute(graph, source)
    distances = {}
    graph.keys.each { |node| distances[node] = Float::INFINITY }
    distances[source] = 0
    
    pq = MinHeap.new
    pq.push(source, 0)
    
    until pq.empty?
      node, dist = pq.extract_min
      next if dist > distances[node]
      
      neighbors = graph[node] || []
      neighbors.each do |neighbor, weight|
        new_dist = dist + weight
        
        if new_dist < distances[neighbor].to_f
          distances[neighbor] = new_dist
          if pq.contains?(neighbor)
            pq.decrease_key(neighbor, new_dist)
          else
            pq.push(neighbor, new_dist)
          end
        end
      end
    end
    
    distances
  end
end