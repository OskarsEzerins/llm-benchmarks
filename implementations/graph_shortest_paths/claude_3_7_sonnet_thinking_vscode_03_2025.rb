class MinHeap
  def initialize
    @heap = []
  end

  def empty?
    @heap.empty?
  end

  def push(node, priority)
    @heap << [node, priority]
    index = @heap.size - 1

    while index > 0
      parent = (index - 1) / 2
      break if @heap[parent][1] <= @heap[index][1]

      @heap[parent], @heap[index] = @heap[index], @heap[parent]
      index = parent
    end
  end

  def extract_min
    return nil if @heap.empty?

    min = @heap[0]

    if @heap.size > 1
      @heap[0] = @heap.pop

      index = 0
      loop do
        smallest = index
        left = 2 * index + 1
        right = 2 * index + 2

        smallest = left if left < @heap.size && @heap[left][1] < @heap[smallest][1]
        smallest = right if right < @heap.size && @heap[right][1] < @heap[smallest][1]

        break if smallest == index

        @heap[index], @heap[smallest] = @heap[smallest], @heap[index]
        index = smallest
      end
    else
      @heap.pop
    end

    min
  end
end

class GraphShortestPaths
  def self.compute(graph, source)
    dist = {}
    visited = {}

    dist[source] = 0
    pq = MinHeap.new
    pq.push(source, 0)

    while (node_data = pq.extract_min)
      u, dist_u = node_data

      next if visited[u]
      visited[u] = true

      graph[u]&.each do |v, weight|
        new_dist = dist_u + weight

        if !dist[v] || new_dist < dist[v]
          dist[v] = new_dist
          pq.push(v, new_dist)
        end
      end
    end

    graph.each_key do |node|
      dist[node] ||= Float::INFINITY
    end

    dist
  end
end
