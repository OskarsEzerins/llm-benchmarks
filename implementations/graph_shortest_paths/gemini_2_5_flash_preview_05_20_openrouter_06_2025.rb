# frozen_string_literal: true

class GraphShortestPaths
  # Custom Binary Heap implementation for a min-priority queue.
  # Stores [priority, value] pairs, ordered by priority.
  class MinPriorityQueue
    def initialize
      @heap = []
      @pos = {} # Stores the current index of each value in the heap
    end

    def <<(item)
      priority, value = item
      if @pos.key?(value)
        # Update existing item if new priority is lower
        idx = @pos[value]
        if priority < @heap[idx][0]
          @heap[idx] = item
          bubble_up(idx)
        end
      else
        # Add new item
        @heap << item
        idx = @heap.length - 1
        @pos[value] = idx
        bubble_up(idx)
      end
      self
    end

    def pop
      return nil if empty?

      swap(0, @heap.length - 1)
      item = @heap.pop
      @pos.delete(item[1])

      bubble_down(0) unless empty?
      item
    end

    def empty?
      @heap.empty?
    end

    private

    def bubble_up(idx)
      parent_idx = (idx - 1) / 2
      while idx > 0 && @heap[idx][0] < @heap[parent_idx][0]
        swap(idx, parent_idx)
        idx = parent_idx
        parent_idx = (idx - 1) / 2
      end
    end

    def bubble_down(idx)
      left_child_idx = 2 * idx + 1
      right_child_idx = 2 * idx + 2
      smallest_idx = idx

      if left_child_idx < @heap.length && @heap[left_child_idx][0] < @heap[smallest_idx][0]
        smallest_idx = left_child_idx
      end

      if right_child_idx < @heap.length && @heap[right_child_idx][0] < @heap[smallest_idx][0]
        smallest_idx = right_child_idx
      end

      if smallest_idx != idx
        swap(idx, smallest_idx)
        bubble_down(smallest_idx)
      end
    end

    def swap(i, j)
      @pos[@heap[i][1]] = j
      @pos[@heap[j][1]] = i
      @heap[i], @heap[j] = @heap[j], @heap[i]
    end
  end

  INFINITY = Float::INFINITY

  # Computes shortest path distances from a source node using Dijkstra's algorithm.
  #
  # @param graph [Hash] The graph represented as an adjacency list.
  #   Keys are node identifiers (integers), values are arrays of [neighbor, weight] pairs.
  # @param source [Integer] The starting node for shortest path computation.
  # @return [Hash] A hash where keys are node identifiers and values are their
  #   shortest distance from the source. Nodes unreachable from the source
  #   will have a distance of INFINITY.
  def self.compute(graph, source)
    distances = {}
    
    # Initialize distances: 0 for source, INFINITY for others
    graph.each_key { |node| distances[node] = INFINITY }
    distances[source] = 0

    priority_queue = MinPriorityQueue.new
    priority_queue << [0, source] # [distance, node]

    until priority_queue.empty?
      current_distance, current_node = priority_queue.pop

      # If we've already found a shorter path to current_node, skip
      next if current_distance > distances[current_node]

      # Iterate over neighbors
      (graph[current_node] || []).each do |neighbor, weight|
        distance = current_distance + weight

        # If a shorter path to neighbor is found, update distance and add/update in queue
        if distance < distances[neighbor]
          distances[neighbor] = distance
          priority_queue << [distance, neighbor]
        end
      end
    end

    distances
  end
end