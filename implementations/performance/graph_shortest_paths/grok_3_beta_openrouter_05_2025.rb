# frozen_string_literal: true

class GraphShortestPaths
  class BinaryHeap
    attr_reader :heap

    def initialize
      @heap = []
    end

    def push(node, priority)
      @heap << [priority, node]
      bubble_up(@heap.size - 1)
    end

    def pop
      return nil if @heap.empty?
      return @heap.pop if @heap.size == 1

      root = @heap[0]
      @heap[0] = @heap.pop
      bubble_down(0)
      root
    end

    def empty?
      @heap.empty?
    end

    private

    def bubble_up(index)
      parent = (index - 1) / 2
      while index > 0 && @heap[parent][0] > @heap[index][0]
        @heap[parent], @heap[index] = @heap[index], @heap[parent]
        index = parent
        parent = (index - 1) / 2
      end
    end

    def bubble_down(index)
      size = @heap.size
      loop do
        smallest = index
        left = 2 * index + 1
        right = 2 * index + 2

        smallest = left if left < size && @heap[left][0] < @heap[smallest][0]
        smallest = right if right < size && @heap[right][0] < @heap[smallest][0]

        break if smallest == index

        @heap[index], @heap[smallest] = @heap[smallest], @heap[index]
        index = smallest
      end
    end
  end

  def self.compute(graph, source)
    distances = Hash.new(Float::INFINITY)
    distances[source] = 0

    pq = BinaryHeap.new
    pq.push(source, 0)

    until pq.empty?
      dist, node = pq.pop
      next if dist > distances[node]

      next unless graph.key?(node)

      graph[node].each do |neighbor, weight|
        new_dist = dist + weight
        if new_dist < distances[neighbor]
          distances[neighbor] = new_dist
          pq.push(neighbor, new_dist)
        end
      end
    end

    distances
  end
end