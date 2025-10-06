class GraphShortestPaths
  def self.compute(graph, source)
    distances = {}
    visited = {}
    pq = PriorityQueue.new

    distances[source] = 0
    pq.push(source, 0)

    until pq.empty?
      current_distance, current_node = pq.pop
      next if visited[current_node]
      visited[current_node] = true

      neighbors = graph[current_node]
      if neighbors
        neighbors.each do |neighbor, weight|
          next if visited[neighbor]
          new_distance = current_distance + weight
          if distances[neighbor].nil? || new_distance < distances[neighbor]
            distances[neighbor] = new_distance
            pq.push(neighbor, new_distance)
          end
        end
      end
    end

    distances
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
      return nil if @heap.empty?
      result = @heap[0]
      last = @heap.pop
      @positions.delete(result[1])
      unless @heap.empty?
        @heap[0] = last
        @positions[last[1]] = 0
        bubble_down(0)
      end
      result
    end

    def empty?
      @heap.empty?
    end

    private

    def decrease_key(item, new_priority)
      index = @positions[item]
      old_priority = @heap[index][0]
      if new_priority < old_priority
        @heap[index][0] = new_priority
        bubble_up(index)
      end
    end

    def bubble_up(index)
      return if index == 0
      parent_index = (index - 1) >> 1
      if @heap[index][0] < @heap[parent_index][0]
        swap(index, parent_index)
        bubble_up(parent_index)
      end
    end

    def bubble_down(index)
      left_child_index = (index << 1) + 1
      right_child_index = left_child_index + 1
      smallest = index

      if left_child_index < @heap.length && @heap[left_child_index][0] < @heap[smallest][0]
        smallest = left_child_index
      end

      if right_child_index < @heap.length && @heap[right_child_index][0] < @heap[smallest][0]
        smallest = right_child_index
      end

      if smallest != index
        swap(index, smallest)
        bubble_down(smallest)
      end
    end

    def swap(i, j)
      @positions[@heap[i][1]] = j
      @positions[@heap[j][1]] = i
      @heap[i], @heap[j] = @heap[j], @heap[i]
    end
  end
end