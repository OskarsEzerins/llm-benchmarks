class GraphShortestPaths
  def self.compute(graph, source)
    distances = {}
    visited = {}
    pq = PriorityQueue.new

    graph.each_key { |node| distances[node] = Float::INFINITY }
    distances[source] = 0
    pq.push(source, 0)

    until pq.empty?
      current_distance, current_node = pq.pop
      next if visited[current_node]
      visited[current_node] = true

      graph[current_node].each do |neighbor, weight|
        next if visited[neighbor]
        new_distance = current_distance + weight
        if new_distance < distances[neighbor]
          distances[neighbor] = new_distance
          pq.push(neighbor, new_distance)
        end
      end
    end

    distances
  end
end

class PriorityQueue
  def initialize
    @heap = []
    @positions = {}
  end

  def push(item, priority)
    if @positions.key?(item)
      decrease_key(item, priority)
    else
      @heap << [priority, item]
      @positions[item] = @heap.length - 1
      bubble_up(@heap.length - 1)
    end
  end

  def pop
    return nil if empty?
    result = @heap[0]
    last_item = @heap.pop
    @positions.delete(result[1])

    unless empty?
      @heap[0] = last_item
      @positions[last_item[1]] = 0
      bubble_down(0)
    end

    [result[0], result[1]]
  end

  def empty?
    @heap.empty?
  end

  private

  def decrease_key(item, new_priority)
    index = @positions[item]
    old_priority = @heap[index][0]
    return if new_priority >= old_priority

    @heap[index][0] = new_priority
    bubble_up(index)
  end

  def bubble_up(index)
    while index > 0
      parent_index = (index - 1) >> 1
      break if @heap[index][0] >= @heap[parent_index][0]

      swap(index, parent_index)
      index = parent_index
    end
  end

  def bubble_down(index)
    while (left_child_index = (index << 1) + 1) < @heap.length
      smallest_child_index = left_child_index
      right_child_index = left_child_index + 1

      if right_child_index < @heap.length && @heap[right_child_index][0] < @heap[left_child_index][0]
        smallest_child_index = right_child_index
      end

      break if @heap[index][0] <= @heap[smallest_child_index][0]

      swap(index, smallest_child_index)
      index = smallest_child_index
    end
  end

  def swap(i, j)
    @heap[i], @heap[j] = @heap[j], @heap[i]
    @positions[@heap[i][1]] = i
    @positions[@heap[j][1]] = j
  end
end