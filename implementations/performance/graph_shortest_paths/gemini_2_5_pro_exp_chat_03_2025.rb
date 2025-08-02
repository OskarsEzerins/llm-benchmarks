# frozen_string_literal: true

# Optimized Min-Heap implementation for Dijkstra's algorithm
# Stores [priority, value] pairs, prioritizing lower priority values.
class MinHeap
  attr_reader :size

  # Initializes an empty MinHeap.
  # The heap structure is stored in @heap, starting from index 1 for easier parent/child calculation.
  def initialize
    @heap = [nil] # @heap[0] is unused (sentinel or simplifies indexing)
    @size = 0
  end

  # Adds an element with a given priority and value to the heap.
  # Time complexity: O(log N), where N is the number of elements in the heap.
  #
  # @param priority [Numeric] The priority of the element (lower values are higher priority).
  # @param value [Object] The value associated with the priority.
  def push(priority, value)
    @size += 1
    @heap[@size] = [priority, value]
    bubble_up(@size)
  end

  # Removes and returns the element [priority, value] with the lowest priority (minimum value) from the heap.
  # Returns nil if the heap is empty.
  # Time complexity: O(log N).
  #
  # @return [Array, nil] The [priority, value] pair with the lowest priority, or nil if empty.
  def pop
    return nil if @size == 0

    min_item = @heap[1] # The root element has the minimum priority

    # Replace the root with the last element and reduce size
    last_item = @heap[@size]
    @heap[@size] = nil # Help garbage collection
    @size -= 1

    # If the heap is not empty after removal, restore heap property
    if @size > 0
      @heap[1] = last_item
      bubble_down(1) # Move the new root down to its correct position
    end

    min_item
  end

  # Checks if the heap is empty.
  # Time complexity: O(1).
  #
  # @return [Boolean] true if the heap has no elements, false otherwise.
  def empty?
    @size == 0
  end

  private

  # Moves the element at index k up the heap tree to maintain the heap property.
  # Compares the element with its parent and swaps if it has a lower priority.
  # Time complexity: O(log N).
  #
  # @param k [Integer] The index of the element to bubble up.
  def bubble_up(k)
    parent_idx = k / 2 # Integer division finds parent index
    # While not at the root (k > 1) and the current node's priority is less than its parent's
    while k > 1 && @heap[parent_idx][0] > @heap[k][0]
      swap(k, parent_idx)
      k = parent_idx
      parent_idx = k / 2
    end
  end

  # Moves the element at index k down the heap tree to maintain the heap property.
  # Compares the element with its children and swaps with the child having the lowest priority, if necessary.
  # Time complexity: O(log N).
  #
  # @param k [Integer] The index of the element to bubble down.
  def bubble_down(k)
    loop do
      left_child_idx = 2 * k
      right_child_idx = 2 * k + 1
      smallest_idx = k # Assume current node is the smallest initially

      # Check left child: if it exists and has lower priority than smallest_idx
      if left_child_idx <= @size && @heap[left_child_idx][0] < @heap[smallest_idx][0]
        smallest_idx = left_child_idx
      end

      # Check right child: if it exists and has lower priority than smallest_idx
      if right_child_idx <= @size && @heap[right_child_idx][0] < @heap[smallest_idx][0]
        smallest_idx = right_child_idx
      end

      # If the smallest element is the current node k, heap property is satisfied locally
      break if smallest_idx == k

      # Otherwise, swap with the smallest child and continue bubbling down from that child's position
      swap(k, smallest_idx)
      k = smallest_idx
    end
  end

  # Swaps the elements at two given indices in the heap array.
  # Time complexity: O(1).
  #
  # @param i [Integer] The first index.
  # @param j [Integer] The second index.
  def swap(i, j)
    @heap[i], @heap[j] = @heap[j], @heap[i]
  end
end


# Computes shortest path distances from a source node in a weighted directed graph
# using Dijkstra's algorithm implemented with a custom MinHeap priority queue.
class GraphShortestPaths
  # Represents infinity for distance calculations.
  INFINITY = Float::INFINITY

  # Computes the shortest distances from the source node to all reachable nodes.
  # The graph is represented as a Hash where keys are node IDs (Integers) and
  # values are Arrays of [neighbor_id, edge_weight] pairs. Weights must be non-negative.
  #
  # Performance is prioritized; uses an optimized MinHeap and avoids unnecessary operations.
  #
  # @param graph [Hash{Integer => Array<Array(Integer, Integer)>}] The graph structure.
  # @param source [Integer] The starting node identifier.
  # @return [Hash{Integer => Float}] A hash mapping reachable node IDs to their shortest distance
  #   from the source. Unreachable nodes are not included in the result hash.
  def self.compute(graph, source)
    # Initialize distances: default to INFINITY, source distance is 0.
    # Using Hash.new(INFINITY) avoids pre-populating for all possible nodes.
    distances = Hash.new(INFINITY)
    distances[source] = 0

    # Priority queue stores [distance, node_id] pairs.
    pq = MinHeap.new
    pq.push(0, source) # Start with the source node

    while !pq.empty?
      # Extract node 'u' with the smallest distance 'dist' found so far.
      dist, u = pq.pop

      # Optimization: If the extracted distance is greater than the already known shortest
      # distance to 'u', this entry is stale (we found a shorter path earlier), so skip it.
      # This check effectively handles the "decrease key" aspect without needing a complex PQ.
      next if dist > distances[u]

      # Explore neighbors of node 'u'.
      # Use `graph[u]` which returns nil if `u` is not a key (no outgoing edges defined).
      neighbors = graph[u]
      if neighbors # Check if neighbors is not nil
          i = 0
          len = neighbors.length
          while i < len # Manual loop potentially faster than .each
            v, weight = neighbors[i]

            # Calculate distance to neighbor 'v' through 'u'.
            new_dist = dist + weight # MUST use 'dist' from PQ, not distances[u]

            # Relaxation step: If this path is shorter than the known shortest path to 'v'.
            if new_dist < distances[v]
              # Update the shortest distance to 'v'.
              distances[v] = new_dist
              # Add the new shorter path candidate to the priority queue.
              # Duplicates may be added, but the 'dist > distances[u]' check handles them.
              pq.push(new_dist, v)
            end
            i += 1
          end
      end
    end

    # Return the hash containing shortest distances to all nodes reachable from the source.
    # Nodes never reached will retain their default INFINITY value via Hash.new and thus
    # won't be included explicitly unless they were somehow added and then determined
    # to have INFINITY distance (which shouldn't happen with non-negative weights).
    # The source itself will be included with distance 0 if it exists.
    distances
  end
end
