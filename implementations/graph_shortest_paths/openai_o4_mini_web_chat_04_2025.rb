class GraphShortestPaths
  def self.compute(graph, source)
    graph.default = []
    dist = {}
    graph.each_key { |v| dist[v] = Float::INFINITY }
    dist[source] = 0
    heap = BinaryMinHeap.new
    heap.push(source, 0)
    until heap.empty?
      u, d = heap.pop
      next if d > dist[u]
      graph[u].each do |v, w|
        nd = d + w
        if nd < dist[v]
          dist[v] = nd
          heap.push(v, nd)
        end
      end
    end
    dist
  end
end

class BinaryMinHeap
  def initialize
    @heap = []
  end

  def push(node, priority)
    @heap << [priority, node]
    sift_up(@heap.size - 1)
  end

  def pop
    return if @heap.empty?
    min = @heap[0]
    last = @heap.pop
    if @heap.any?
      @heap[0] = last
      sift_down(0)
    end
    [min[1], min[0]]
  end

  def empty?
    @heap.empty?
  end

  private

  def sift_up(i)
    while i > 0
      p = (i - 1) >> 1
      break if @heap[p][0] <= @heap[i][0]
      @heap[p], @heap[i] = @heap[i], @heap[p]
      i = p
    end
  end

  def sift_down(i)
    size = @heap.size
    loop do
      l = (i << 1) + 1
      r = l + 1
      smallest = i
      smallest = l if l < size && @heap[l][0] < @heap[smallest][0]
      smallest = r if r < size && @heap[r][0] < @heap[smallest][0]
      break if smallest == i
      @heap[i], @heap[smallest] = @heap[smallest], @heap[i]
      i = smallest
    end
  end
end
