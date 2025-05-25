# graph_shortest_paths.rb

class GraphShortestPaths
  # Custom Binary Heap implementation for Priority Queue
  class MinHeap
    def initialize
      @heap = []
    end

    def insert(node, priority)
      @heap << [priority, node]
      bubble_up(@heap.size - 1)
    end

    def extract_min
      return nil if empty?

      # Swap root with last element
      @heap[0], @heap[-1] = @heap[-1], @heap[0]
      min = @heap.pop

      # Restore heap property
      bubble_down(0) unless empty?

      min
    end

    def update_priority(node, new_priority)
      index = @heap.index { |(_, n)| n == node }
      return unless index

      old_priority, _ = @heap[index]
      @heap[index][0] = new_priority

      if new_priority < old_priority
        bubble_up(index)
      elsif new_priority > old_priority
        bubble_down(index)
      end
    end

    def empty?
      @heap.empty?
    end

    private

    def bubble_up(index)
      parent_index = (index - 1) / 2
      return if index <= 0 || @heap[parent_index][0] <= @heap[index][0]

      @heap[parent_index], @heap[index] = @heap[index], @heap[parent_index]
      bubble_up(parent_index)
    end

    def bubble_down(index)
      child_index = 2 * index + 1
      return if child_index >= @heap.size

      right_child = child_index + 1
      if right_child < @heap.size && @heap[right_child][0] < @heap[child_index][0]
        child_index = right_child
      end

      return if @heap[index][0] <= @heap[child_index][0]

      @heap[index], @heap[child_index] = @heap[child_index], @heap[index]
      bubble_down(child_index)
    end
  end

  # Compute shortest paths using Dijkstra's algorithm
  def self.compute(graph, source)
    distances = {}
    visited = {}
    pq = MinHeap.new

    graph.keys.each { |node| distances[node] = Float::INFINITY }
    distances[source] = 0
    pq.insert(source, 0)

    while !pq.empty?
      current_distance, current_node = pq.extract_min
      next if visited[current_node]

      visited[current_node] = true

      neighbors = graph[current_node] || []
      neighbors.each do |neighbor, weight|
        next if visited[neighbor]

        new_distance = current_distance + weight
        if new_distance < distances[neighbor]
          distances[neighbor] = new_distance
          pq.update_priority(neighbor, new_distance) || pq.insert(neighbor, new_distance)
        end
      end
    end

    distances
  end
end

# Example usage:
if __FILE__ == $0
  graph = {
    0 => [[1, 10], [2, 3]],
    1 => [[2, 1]],
    2 => []
  }
  source = 0
  result = GraphShortestPaths.compute(graph, source)
  puts "Shortest distances from node #{source}: #{result}"
end
