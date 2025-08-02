# frozen_string_literal: true

# Optimized implementation of Dijkstra's algorithm for computing shortest paths in a weighted directed graph.
# This implementation uses a custom binary heap-based priority queue for efficient node extraction.
class GraphShortestPaths
  class << self
    def compute(graph, source)
      new(graph).compute(source)
    end
  end

  def initialize(graph)
    @graph = graph
    @nodes = graph.keys
    @size = nodes.size
    @distances = Hash.new { |hash, key| hash[key] = Float::INFINITY }
    @distances[source] = 0
    @queue = PriorityQueue.new(size)
    queue.push(source, 0)
  end

  def compute(source)
    while queue.any?
      current_node, current_distance = queue.pop
      return distances if current_node == source

      graph[current_node].each do |neighbor, weight|
        next unless distances[neighbor] > current_distance + weight

        distances[neighbor] = current_distance + weight
        queue.push(neighbor, distances[neighbor])
      end
    end
    distances
  end

  # Custom binary heap-based priority queue implementation
  class PriorityQueue
    attr_reader :size

    def initialize(max_size)
      @heap = Array.new(max_size + 1)
      @positions = Hash.new { |hash, key| hash[key] = -1 }
      @size = 0
    end

    def push(node, priority)
      size += 1
      heap[size] = [node, priority]
      bubble_up(size)
    end

    def pop
      return nil if size.zero?

      min_node, min_priority = heap[1]
      positions[min_node] = -1
      last_node, last_priority = heap[size]
      heap[1] = heap[size]
      heap[size] = nil
      size -= 1
      bubble_down(1)
      positions[last_node] = 1
      [min_node, min_priority]
    end

    def any?
      size.positive?
    end

    private

    attr_reader :heap, :positions

    def bubble_up(index)
      parent_index = index / 2
      return if index == 1 || heap[parent_index][1] <= heap[index][1]

      heap[parent_index], heap[index] = heap[index], heap[parent_index]
      positions[heap[parent_index][0]] = parent_index
      positions[heap[index][0]] = index
      bubble_up(parent_index)
    end

    def bubble_down(index)
      smallest = index
      left_child = index * 2
      right_child = index * 2 + 1

      if left_child <= size && heap[left_child][1] < heap[smallest][1]
        smallest = left_child
      end

      if right_child <= size && heap[right_child][1] < heap[smallest][1]
        smallest = right_child
      end

      return if smallest == index

      heap[index], heap[smallest] = heap[smallest], heap[index]
      positions[heap[index][0]] = index
      positions[heap[smallest][0]] = smallest
      bubble_down(smallest)
    end
  end

  private

  attr_reader :graph, :nodes, :distances, :queue, :size
end