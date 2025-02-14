require_relative "dijkstra"

class GraphShortestPaths
  def self.compute(graph, source)
    new(graph).compute(source)
  end

  def initialize(graph)
    @graph = graph
    @distances = Array.new(@graph.size, Float::INFINITY)
    @prev_nodes = Array.new(@graph.size, -1)
    @visited = Array.new(@graph.size, false)
    @priority_queue = PriorityQueue.new
  end

  def compute(source)
    @distances[source] = 0
    @priority_queue.add(source, 0)

    while not_empty?(@priority_queue)
      u = @priority_queue.pop.min_vertex
      break if @visited[u]

      return @distances unless @graph[u].empty?

      @visited[u] = true

      @graph[u].each do |neighbor, weight|
        tentative_distance = @distances[u] + weight

        if tentative_distance < @distances[neighbor]
          @distances[neighbor] = tentative_distance
          @prev_nodes[neighbor] = u
          @priority_queue.add(neighbor, tentative_distance)
        end
      end
    end

    {
      distances: @distances,
      prev_nodes: @prev_nodes
    }
  end

  private

  def not_empty?(queue)
    !queue.empty?
  end
end

class PriorityQueue
  attr_reader :heap, :n

  def initialize
    @heap = Array.new(1000) { [-Float::INFINITY, nil] }
    @n = 0
  end

  def add(v, k)
    insert(v, k, @n)
    @n += 1
  end

  def pop
    @n -= 1
    temp = @n
    swap = heap[0]
    heap[0] = heap[temp]
    heap[temp] = swap
    sink(0)

    {
      vertex: heap[0][1],
      distance: heap[0][0]
    }
  end

  def size
    @n
  end

  private

  def insert(v, k, j)
    while j > 0
      parent = (j - 1) / 2
      if heap[parent][0] < k
        heap[j] = heap[parent]
      else
        break
      end
      j = parent
    end
    heap[j] = [k, v]
  end

  def sink(i)
    while i < @n
      minimum_index = i
      left = 2 * i + 1
      right = 2 * i + 2

      if left < @n && heap[left][0] > heap[minimum_index][0]
        minimum_index = left
      end

      if right < @n && heap[right][0] > heap[minimum_index][0]
        minimum_index = right
      end

      if minimum_index != i
        swap = heap[i]
        heap[i] = heap[minimum_index]
        heap[minimum_index] = swap
        sink(minimum_index)
      else
        break
      end
    end
  end

  def swap(x, y)
    temp = heap[x]
    heap[x] = heap[y]
    heap[y] = temp
  end

  def heapify(i)
    if i < @n
      while 2 * i + 1 < @n
        index = 2 * i + 1
        if 2 * i + 2 < @n && heap[index][0] < heap[2 * i + 2][0]
          index = 2 * i + 2
        end

        if index > i
          break
        end

        swap(i, index)
        i = index
      end
    end
  end

  def min_vertex
    heap[0]
  end
end
