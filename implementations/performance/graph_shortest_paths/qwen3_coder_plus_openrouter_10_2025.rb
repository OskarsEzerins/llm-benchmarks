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

  def push(node, priority)
    if @positions.key?(node)
      update_priority(node, priority)
    else
      insert_new(node, priority)
    end
  end

  def pop
    return nil if empty?

    root = @heap[0]
    last_element = @heap.pop
    @positions.delete(root[1])

    unless empty?
      @heap[0] = last_element
      @positions[last_element[1]] = 0
      sift_down(0)
    end

    [root[0], root[1]]
  end

  def empty?
    @heap.empty?
  end

  private

  def insert_new(node, priority)
    entry = [priority, node]
    @heap << entry
    index = @heap.size - 1
    @positions[node] = index
    sift_up(index)
  end

  def update_priority(node, new_priority)
    index = @positions[node]
    old_priority = @heap[index][0]

    if new_priority < old_priority
      @heap[index][0] = new_priority
      sift_up(index)
    end
  end

  def sift_up(index)
    return if index == 0

    parent_index = (index - 1) >> 1
    if @heap[index][0] < @heap[parent_index][0]
      swap(index, parent_index)
      sift_up(parent_index)
    end
  end

  def sift_down(index)
    left_child_index = (index << 1) + 1
    right_child_index = left_child_index + 1
    smallest = index

    if left_child_index < @heap.size && @heap[left_child_index][0] < @heap[smallest][0]
      smallest = left_child_index
    end

    if right_child_index < @heap.size && @heap[right_child_index][0] < @heap[smallest][0]
      smallest = right_child_index
    end

    if smallest != index
      swap(index, smallest)
      sift_down(smallest)
    end
  end

  def swap(i, j)
    @heap[i], @heap[j] = @heap[j], @heap[i]
    @positions[@heap[i][1]] = i
    @positions[@heap[j][1]] = j
  end
end