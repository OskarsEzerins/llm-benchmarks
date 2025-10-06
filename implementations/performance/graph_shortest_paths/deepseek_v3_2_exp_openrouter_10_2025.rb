class GraphShortestPaths
  def self.compute(graph, source)
    new(graph, source).compute
  end

  def initialize(graph, source)
    @graph = graph
    @n = graph.size
    @dist = Array.new(@n, Float::INFINITY)
    @dist[source] = 0
    @visited = Array.new(@n, false)
    @heap = MinHeap.new(@n)
    @heap.insert(source, 0)
  end

  def compute
    while @heap.size > 0
      u = @heap.extract_min
      next if @visited[u]
      @visited[u] = true
      
      @graph[u]&.each do |v, weight|
        next if @visited[v]
        alt = @dist[u] + weight
        if alt < @dist[v]
          @dist[v] = alt
          if @heap.contains?(v)
            @heap.decrease_key(v, alt)
          else
            @heap.insert(v, alt)
          end
        end
      end
    end
    
    @dist.map { |d| d == Float::INFINITY ? -1 : d }
  end
end

class MinHeap
  def initialize(capacity)
    @heap = []
    @size = 0
    @pos = Array.new(capacity, -1)
    @key = Array.new(capacity, Float::INFINITY)
  end

  def size
    @size
  end

  def contains?(v)
    @pos[v] != -1
  end

  def insert(v, key_val)
    @size += 1
    i = @size - 1
    @heap[i] = v
    @pos[v] = i
    @key[v] = key_val
    heapify_up(i)
  end

  def extract_min
    return nil if @size == 0
    
    root = @heap[0]
    last = @heap[@size - 1]
    @heap[0] = last
    @pos[last] = 0
    @pos[root] = -1
    @size -= 1
    heapify_down(0)
    root
  end

  def decrease_key(v, key_val)
    i = @pos[v]
    return if i == -1 || @key[v] <= key_val
    
    @key[v] = key_val
    heapify_up(i)
  end

  private

  def heapify_up(i)
    while i > 0 && @key[@heap[parent(i)]] > @key[@heap[i]]
      swap(i, parent(i))
      i = parent(i)
    end
  end

  def heapify_down(i)
    l = left(i)
    r = right(i)
    smallest = i
    
    smallest = l if l < @size && @key[@heap[l]] < @key[@heap[smallest]]
    smallest = r if r < @size && @key[@heap[r]] < @key[@heap[smallest]]
    
    if smallest != i
      swap(i, smallest)
      heapify_down(smallest)
    end
  end

  def parent(i)
    (i - 1) / 2
  end

  def left(i)
    2 * i + 1
  end

  def right(i)
    2 * i + 2
  end

  def swap(i, j)
    @heap[i], @heap[j] = @heap[j], @heap[i]
    @pos[@heap[i]] = i
    @pos[@heap[j]] = j
  end
end