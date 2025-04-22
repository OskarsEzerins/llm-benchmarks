# frozen_string_literal: true

class BinaryHeap
  def initialize
    @heap = []
    @node_positions = {}  # Track positions for O(1) decrease_key
  end

  def empty?
    @heap.empty?
  end

  def push(node, priority)
    @heap << [priority, node]
    position = @heap.size - 1
    @node_positions[node] = position
    bubble_up(position)
  end

  def pop
    return nil if @heap.empty?

    min_priority, min_node = @heap[0]
    @node_positions.delete(min_node)

    if @heap.size > 1
      @heap[0] = @heap.pop
      @node_positions[@heap[0][1]] = 0
      bubble_down(0)
    else
      @heap.pop
    end

    [min_node, min_priority]
  end

  def decrease_key(node, new_priority)
    return unless (position = @node_positions[node])
    return if new_priority >= @heap[position][0]

    @heap[position][0] = new_priority
    bubble_up(position)
  end

  private

  def bubble_up(pos)
    while pos > 0
      parent = (pos - 1) / 2
      break if @heap[parent][0] <= @heap[pos][0]

      swap(parent, pos)
      pos = parent
    end
  end

  def bubble_down(pos)
    loop do
      min = pos
      left = 2 * pos + 1
      right = left + 1

      min = left if left < @heap.size && @heap[left][0] < @heap[min][0]
      min = right if right < @heap.size && @heap[right][0] < @heap[min][0]

      break if min == pos

      swap(pos, min)
      pos = min
    end
  end

  def swap(i, j)
    @heap[i], @heap[j] = @heap[j], @heap[i]
    @node_positions[@heap[i][1]] = i
    @node_positions[@heap[j][1]] = j
  end
end

class GraphShortestPaths
  INFINITY = Float::INFINITY

  def self.compute(graph, source)
    new(graph, source).compute
  end

  def initialize(graph, source)
    @graph = graph
    @source = source
    @distances = {}
    @pq = BinaryHeap.new
  end

  def compute
    # Initialize distances
    @graph.each_key do |node|
      @distances[node] = INFINITY
    end
    @distances[@source] = 0

    # Initialize priority queue with source
    @pq.push(@source, 0)

    # Process nodes
    until @pq.empty?
      node, dist = @pq.pop
      next if dist > @distances[node]  # Skip if we've found a better path

      # Process each neighbor
      @graph[node]&.each do |neighbor, weight|
        new_dist = dist + weight

        if new_dist < @distances[neighbor]
          @distances[neighbor] = new_dist
          @pq.push(neighbor, new_dist)
        end
      end
    end

    @distances
  end
end
