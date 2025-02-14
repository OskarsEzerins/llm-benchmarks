class GraphShortestPaths
  class PriorityQueue
    def initialize
      @heap = []
    end

    def push(item, priority)
      @heap << [priority, item]
      bubble_up(@heap.size - 1)
    end

    def pop
      return nil if empty?

      min_priority, min_item = @heap[0]
      last = @heap.pop
      unless empty?
        @heap[0] = last
        bubble_down(0)
      end
      return min_item, min_priority
    end

    def empty?
      @heap.empty?
    end

    private

    def bubble_up(i)
      parent = (i - 1) / 2
      return if i == 0 || @heap[parent][0] <= @heap[i][0]

      @heap[i], @heap[parent] = @heap[parent], @heap[i]
      bubble_up(parent)
    end

    def bubble_down(i)
      left = 2 * i + 1
      right = 2 * i + 2
      smallest = i

      smallest = left if left < @heap.size && @heap[left][0] < @heap[smallest][0]
      smallest = right if right < @heap.size && @heap[right][0] < @heap[smallest][0]

      return if smallest == i

      @heap[i], @heap[smallest] = @heap[smallest], @heap[i]
      bubble_down(smallest)
    end
  end


  def self.compute(graph, source)
    distances = {}
    graph.each_key { |node| distances[node] = Float::INFINITY }
    distances[source] = 0

    pq = PriorityQueue.new
    pq.push(source, 0)

    while !pq.empty?
      current_node, current_distance = pq.pop

      next if current_distance > distances[current_node] # Optimization: Skip outdated entries

      graph[current_node].each do |neighbor, weight|
        new_distance = current_distance + weight
        if new_distance < distances[neighbor]
          distances[neighbor] = new_distance
          pq.push(neighbor, new_distance)
        end
      end
    end
    distances # Return the distances hash
  end
end
