# frozen_string_literal: true

# Implements a min-priority queue using a binary heap.
# Elements are [priority, value] pairs, ordered by priority.
class MinPriorityQueue
  def initialize
    @heap = []
  end

  def push(priority, value)
    @heap << [priority, value]
    bubble_up(@heap.length - 1)
  end

  def pop
    return nil if empty?

    swap(0, @heap.length - 1)
    min_element = @heap.pop
    bubble_down(0)
    min_element
  end

  def empty?
    @heap.empty?
  end

  private

  def bubble_up(index)
    parent_index = (index - 1) / 2
    while index > 0 && @heap[index][0] < @heap[parent_index][0]
      swap(index, parent_index)
      index = parent_index
      parent_index = (index - 1) / 2
    end
  end

  def bubble_down(index)
    last_index = @heap.length - 1
    while true
      left_child_index = 2 * index + 1
      right_child_index = 2 * index + 2
      smallest_index = index

      if left_child_index <= last_index && @heap[left_child_index][0] < @heap[smallest_index][0]
        smallest_index = left_child_index
      end

      if right_child_index <= last_index && @heap[right_child_index][0] < @heap[smallest_index][0]
        smallest_index = right_child_index
      end

      break if smallest_index == index

      swap(index, smallest_index)
      index = smallest_index
    end
  end

  def swap(i, j)
    @heap[i], @heap[j] = @heap[j], @heap[i]
  end
end

# Computes shortest path distances from a source node using Dijkstra's algorithm.
class GraphShortestPaths
  INFINITY = Float::INFINITY

  # Computes shortest path distances from a source node.
  #
  # @param graph [Hash] The graph represented as an adjacency list.
  #                      Each key is a node identifier (Integer), and its value
  #                      is an Array of [neighbor, weight] pairs.
  # @param source [Integer] The source node.
  # @return [Hash] A hash where keys are node identifiers and values are their
  #                shortest distances from the source. Nodes unreachable from
  #                the source will have a distance of Float::INFINITY.
  def self.compute(graph, source)
    distances = {}
    pq = MinPriorityQueue.new

    # Initialize distances.
    graph.each_key { |node| distances[node] = INFINITY }
    distances[source] = 0
    pq.push(0, source)

    while !pq.empty?
      dist, u = pq.pop

      # Skip if we've found a shorter path to u already.
      next if dist > distances[u]

      # Iterate over neighbors of u.
      (graph[u] || []).each do |v, weight|
        alt = distances[u] + weight
        if alt < distances[v]
          distances[v] = alt
          pq.push(alt, v)
        end
      end
    end

    distances
  end
end