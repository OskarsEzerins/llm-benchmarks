# graph_shortest_paths.rb

class BinaryHeap
  def initialize
    @heap = []
    @positions = {}
  end

  def push(node, priority)
    if @positions.key?(node)
      decrease_key(node, priority)
    else
      @heap << [priority, node]
      @positions[node] = @heap.size - 1
      sift_up(@heap.size - 1)
    end
  end

  def pop
    return if @heap.empty?

    min = @heap.first
    last = @heap.pop
    if !@heap.empty?
      @heap[0] = last
      @positions[last[1]] = 0
      sift_down(0)
    end

    @positions.delete(min[1])
    min[1]
  end

  def empty?
    @heap.empty?
  end

  private

  def sift_up(index)
    while index > 0
      parent = (index - 1) >> 1
      if @heap[index][0] < @heap[parent][0]
        swap(index, parent)
        index = parent
      else
        break
      end
    end
  end

  def sift_down(index)
    size = @heap.size
    loop do
      left = (index << 1) + 1
      right = left + 1
      smallest = index

      smallest = left if left < size && @heap[left][0] < @heap[smallest][0]
      smallest = right if right < size && @heap[right][0] < @heap[smallest][0]

      break if smallest == index

      swap(index, smallest)
      index = smallest
    end
  end

  def decrease_key(node, priority)
    index = @positions[node]
    return if @heap[index][0] <= priority

    @heap[index][0] = priority
    sift_up(index)
  end

  def swap(i, j)
    @positions[@heap[i][1]], @positions[@heap[j][1]] = j, i
    @heap[i], @heap[j] = @heap[j], @heap[i]
  end
end

class GraphShortestPaths
  def self.compute(graph, source)
    distances = Hash.new(Float::INFINITY)
    distances[source] = 0
    heap = BinaryHeap.new
    heap.push(source, 0)

    until heap.empty?
      node = heap.pop
      next unless graph[node]

      graph[node].each do |neighbor, weight|
        new_distance = distances[node] + weight
        if new_distance < distances[neighbor]
          distances[neighbor] = new_distance
          heap.push(neighbor, new_distance)
        end
      end
    end

    distances
  end
end
