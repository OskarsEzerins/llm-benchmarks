class GraphShortestPaths
  def self.compute(graph, source)
    distances = {}
    nodes = graph.keys
    nodes.each { |node| distances[node] = Float::INFINITY }
    distances[source] = 0

    priority_queue = PriorityQueue.new
    priority_queue.push(source, 0)

    while !priority_queue.empty?
      node, priority = priority_queue.pop
      
      next if priority > distances[node]

      graph[node]&.each do |neighbor, weight|
        new_distance = distances[node] + weight
        if new_distance < distances[neighbor]
          distances[neighbor] = new_distance
          priority_queue.push(neighbor, new_distance)
        end
      end
    end

    distances
  end

  class PriorityQueue
    def initialize
      @heap = []
    end

    def push(item, priority)
      @heap.push([item, priority])
      heapify_up(@heap.length - 1)
    end

    def pop
      return nil if empty?

      if @heap.length == 1
        return @heap.pop
      end

      min_item = @heap[0]
      @heap[0] = @heap.pop
      heapify_down(0)
      min_item
    end

    def empty?
      @heap.empty?
    end

    private

    def heapify_up(index)
      while index > 0
        parent_index = (index - 1) / 2
        if @heap[index][1] < @heap[parent_index][1]
          @heap[index], @heap[parent_index] = @heap[parent_index], @heap[index]
          index = parent_index
        else
          break
        end
      end
    end

    def heapify_down(index)
      length = @heap.length
      while true
        left_child_index = 2 * index + 1
        right_child_index = 2 * index + 2
        smallest = index

        if left_child_index < length && @heap[left_child_index][1] < @heap[smallest][1]
          smallest = left_child_index
        end

        if right_child_index < length && @heap[right_child_index][1] < @heap[smallest][1]
          smallest = right_child_index
        end

        if smallest != index
          @heap[index], @heap[smallest] = @heap[smallest], @heap[index]
          index = smallest
        else
          break
        end
      end
    end
  end
end