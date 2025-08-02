class PriorityQueue
  def initialize
    @heap = []
    @index = {}
  end

  def push(node, priority)
    @heap << { node: node, priority: priority }
    @index[node] = @heap.size - 1
    heapify_up(@heap.size - 1)
  end

  def pop
    return nil if @heap.empty?
    root = @heap[0]
    last = @heap.pop
    @index.delete(root[:node])
    if !@heap.empty?
      @heap[0] = last
      @index[last[:node]] = 0
      heapify_down(0)
    end
    root[:node]
  end

  def decrease_priority(node, new_priority)
    return unless @index.key?(node)
    i = @index[node]
    if new_priority < @heap[i][:priority]
      @heap[i][:priority] = new_priority
      heapify_up(i)
    end
  end

  def empty?
    @heap.empty?
  end

  private

  def heapify_up(i)
    parent = (i - 1) / 2
    while i > 0 && @heap[i][:priority] < @heap[parent][:priority]
      swap(i, parent)
      i = parent
      parent = (i - 1) / 2
    end
  end

  def heapify_down(i)
    while true
      left = 2 * i + 1
      right = 2 * i + 2
      smallest = i

      smallest = left if left < @heap.size && @heap[left][:priority] < @heap[smallest][:priority]
      smallest = right if right < @heap.size && @heap[right][:priority] < @heap[smallest][:priority]

      break if smallest == i

      swap(i, smallest)
      i = smallest
    end
  end

  def swap(a, b)
    @heap[a], @heap[b] = @heap[b], @heap[a]
    @index[@heap[a][:node]] = a
    @index[@heap[b][:node]] = b
  end
end

class GraphShortestPaths
  def self.compute(graph, source)
    distances = {}
    previous = {}
    queue = PriorityQueue.new

    graph.each_key do |node|
      distances[node] = Float::INFINITY
      previous[node] = nil
    end

    distances[source] = 0
    queue.push(source, 0)

    until queue.empty?
      current = queue.pop
      next if distances[current] == Float::INFINITY

      graph[current].each do |neighbor, weight|
        alt = distances[current] + weight
        if alt < distances[neighbor]
          distances[neighbor] = alt
          previous[neighbor] = current
          queue.decrease_priority(neighbor, alt)
        end
      end
    end

    distances
  end
end
