class GraphShortestPaths
  class MinHeap
    def initialize
      @heap = []
      @index = {}
    end

    def push(node, dist)
      if @index.key?(node)
        update(node, dist)
      else
        @heap << [dist, node]
        @index[node] = @heap.size - 1
        heapify_up(@heap.size - 1)
      end
    end

    def pop_min
      return nil if @heap.empty?
      swap(0, @heap.size - 1)
      min = @heap.pop
      @index.delete(min[1])
      unless @heap.empty?
        @index[@heap[0][1]] = 0
        heapify_down(0)
      end
      min
    end

    def empty?
      @heap.empty?
    end

    private

    def update(node, new_dist)
      i = @index[node]
      old_dist = @heap[i][0]
      @heap[i][0] = new_dist
      if new_dist < old_dist
        heapify_up(i)
      else
        heapify_down(i)
      end
    end

    def heapify_up(i)
      while i > 0
        parent = (i - 1) / 2
        break if @heap[parent][0] <= @heap[i][0]
        swap(parent, i)
        i = parent
      end
    end

    def heapify_down(i)
      loop do
        left = 2 * i + 1
        right = 2 * i + 2
        smallest = i

        smallest = left if left < @heap.size && @heap[left][0] < @heap[smallest][0]
        smallest = right if right < @heap.size && @heap[right][0] < @heap[smallest][0]

        break if smallest == i
        swap(i, smallest)
        i = smallest
      end
    end

    def swap(i, j)
      @index[@heap[i][1]] = j
      @index[@heap[j][1]] = i
      @heap[i], @heap[j] = @heap[j], @heap[i]
    end
  end

  def self.compute(graph, source)
    dist = {}
    heap = MinHeap.new

    graph.each_key { |node| dist[node] = Float::INFINITY }
    dist[source] = 0
    heap.push(source, 0)

    until heap.empty?
      _, u = heap.pop_min
      next if dist[u] == Float::INFINITY

      graph[u]&.each do |v, w|
        alt = dist[u] + w
        if alt < dist[v]
          dist[v] = alt
          heap.push(v, alt)
        end
      end
    end

    dist
  end
end