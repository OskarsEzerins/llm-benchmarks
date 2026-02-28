class PriorityQueue
  def initialize
    @heap = []
  end

  def push(distance, node)
    @heap << [distance, node]
    index = @heap.size - 1
    while index > 0
      parent = (index - 1) / 2
      if @heap[parent][0] > @heap[index][0]
        @heap[parent], @heap[index] = @heap[index], @heap[parent]
        index = parent
      else
        break
      end
    end
  end

  def pop
    return nil if @heap.empty?
    last_index = @heap.size - 1
    @heap[0], @heap[last_index] = @heap[last_index], @heap[0]
    min = @heap.pop
    bubble_down(0) unless @heap.empty?
    min
  end

  def empty?
    @heap.empty?
  end

  private

  def bubble_down(index)
    size = @heap.size
    loop do
      left = 2 * index + 1
      right = 2 * index + 2
      smallest = index
      if left < size && @heap[left][0] < @heap[smallest][0]
        smallest = left
      end
      if right < size && @heap[right][0] < @heap[smallest][0]
        smallest = right
      end
      break if smallest == index
      @heap[smallest], @heap[index] = @heap[index], @heap[smallest]
      index = smallest
    end
  end
end

class GraphShortestPaths
  INF = 2**60

  def self.compute(graph, source)
    all_nodes = {}
    all_nodes[source] = true
    graph.each do |node, edges|
      all_nodes[node] = true
      edges.each { |neighbor, _| all_nodes[neighbor] = true }
    end

    distances = {}
    all_nodes.each_key { |node| distances[node] = INF }
    distances[source] = 0

    pq = PriorityQueue.new
    pq.push(0, source)

    while !pq.empty?
      dist, node = pq.pop
      next if distances[node] != dist

      if (edges = graph[node])
        edges.each do |neighbor, weight|
          new_dist = dist + weight
          if new_dist < distances[neighbor]
            distances[neighbor] = new_dist
            pq.push(new_dist, neighbor)
          end
        end
      end
    end

    distances
  end
end