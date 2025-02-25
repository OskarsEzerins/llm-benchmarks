class MinHeap
  def initialize
    @heap = []
  end

  def push(key, value)
    @heap << [key, value]
    heapify_up(@heap.size - 1)
  end

  def pop
    return nil if @heap.empty?

    min = @heap[0]
    @heap[0] = @heap.pop
    heapify_down(0) unless @heap.empty?
    min
  end

  def empty?
    @heap.empty?
  end

  def decrease_key(key, new_value)
    index = @heap.index { |k, _| k == key }
    return unless index

    if new_value < @heap[index][1]
      @heap[index][1] = new_value
      heapify_up(index)
    end
  end

  def include?(key)
    @heap.any? { |k, _| k == key }
  end

  private

  def heapify_up(index)
    parent = (index - 1) / 2

    if index > 0 && @heap[parent][1] > @heap[index][1]
      @heap[parent], @heap[index] = @heap[index], @heap[parent]
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
      @heap[index], @heap[smallest] = @heap[smallest], @heap[index]
      heapify_down(smallest)
    end
  end
end

class GraphShortestPaths
  def self.compute(graph, source)
    distances = {}
    graph.keys.each { |node| distances[node] = Float::INFINITY }
    distances[source] = 0

    priority_queue = MinHeap.new
    priority_queue.push(source, 0)

    until priority_queue.empty?
      current_node, current_distance = priority_queue.pop

      next if current_distance > distances[current_node]

      neighbors = graph[current_node] || []
      neighbors.each do |neighbor, weight|
        distance = current_distance + weight

        if distance < distances[neighbor]
          distances[neighbor] = distance
          if priority_queue.include?(neighbor)
            priority_queue.decrease_key(neighbor, distance)
          else
            priority_queue.push(neighbor, distance)
          end
        end
      end
    end

    distances
  end
end
