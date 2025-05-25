# graph_shortest_paths.rb

# This class implements Dijkstra's algorithm using a custom MinPriorityQueue.
# It computes shortest path distances from a source node in a weighted directed graph.
class GraphShortestPaths
  # MinPriorityQueue stores [priority, node_id] pairs and supports efficient
  # extract_min and decrease_key operations, crucial for Dijkstra's algorithm.
  class MinPriorityQueue
    def initialize
      # @heap stores [priority, item_id] pairs.
      # It's a 0-indexed binary heap.
      @heap = []
      # @node_to_index maps an item_id to its current index in the @heap array.
      # This allows O(1) lookup for decrease_key.
      @node_to_index = {}
      # @size tracks the number of elements currently in the heap.
      @size = 0
    end

    # Returns true if the priority queue is empty, false otherwise.
    def empty?
      @size == 0
    end

    # Inserts a node_id with a given priority into the queue.
    # Assumes node_id is not already present or is being added for the first time.
    def insert(node_id, priority)
      # Place the new element at the end of the heap array (logical end).
      @heap[@size] = [priority, node_id]
      @node_to_index[node_id] = @size
      # Sift up from the newly added element's position to maintain heap property.
      sift_up(@size)
      @size += 1
    end

    # Removes and returns the element [priority, node_id] with the minimum priority.
    # Returns nil if the queue is empty.
    def extract_min
      return nil if @size == 0

      min_element = @heap[0]
      min_node_id = min_element[1]

      # Remove the extracted node from the index map.
      @node_to_index.delete(min_node_id)
      @size -= 1 # Logically reduce size first.

      if @size > 0
        # Move the last element in the heap to the root.
        last_element = @heap[@size] # This is the element at the old @size-1 index.
        @heap[0] = last_element
        @node_to_index[last_element[1]] = 0
        # Sift down from the root to restore heap property.
        sift_down(0)
      end
      # The physical array @heap might still hold @heap[@size] (the old last element),
      # but it's outside the logical heap managed by @size. This is generally fine
      # for performance as it avoids shrinking the array.

      min_element
    end

    # Updates the priority of an existing node_id to new_priority.
    # Assumes new_priority is less than the current priority.
    # Assumes node_id is currently in the queue.
    def decrease_key(node_id, new_priority)
      index = @node_to_index[node_id]
      # This return condition should ideally not be met if Dijkstra's logic is correct,
      # as `decrease_key` should only be called on nodes present in the PQ.
      return unless index
      
      @heap[index][0] = new_priority
      sift_up(index)
    end

    # Checks if a node_id is present in the priority queue.
    def has_node?(node_id)
      @node_to_index.key?(node_id)
    end

    private

    # Moves element at `index` up the heap to its correct position.
    def sift_up(index)
      # Parent index calculation: (i - 1) / 2
      # Loop while not at root and current element is smaller than its parent.
      parent_idx = (index - 1) / 2
      while index > 0 && @heap[index][0] < @heap[parent_idx][0]
        swap(index, parent_idx)
        index = parent_idx
        parent_idx = (index - 1) / 2 # Recalculate for next iteration
      end
    end

    # Moves element at `index` down the heap to its correct position.
    def sift_down(index)
      # Loop to find the correct position for the element at `index`.
      loop do
        min_swap_idx = index # Assume current is smallest initially
        left_child_idx = 2 * index + 1
        right_child_idx = 2 * index + 2

        # Check if left child exists and is smaller.
        if left_child_idx < @size && @heap[left_child_idx][0] < @heap[min_swap_idx][0]
          min_swap_idx = left_child_idx
        end

        # Check if right child exists and is smaller (than current or left child).
        if right_child_idx < @size && @heap[right_child_idx][0] < @heap[min_swap_idx][0]
          min_swap_idx = right_child_idx
        end

        # If current element is already in its correct place (smaller than children).
        break if index == min_swap_idx

        swap(index, min_swap_idx)
        index = min_swap_idx # Continue sifting down from the new position.
      end
    end

    # Swaps two elements in the heap at given indices.
    # Also updates their positions in @node_to_index.
    def swap(idx1, idx2)
      node1_id = @heap[idx1][1]
      node2_id = @heap[idx2][1]

      @node_to_index[node1_id] = idx2
      @node_to_index[node2_id] = idx1

      @heap[idx1], @heap[idx2] = @heap[idx2], @heap[idx1]
    end
  end # End of MinPriorityQueue

  # Computes shortest path distances from `source` node to all reachable nodes
  # in the `graph` using Dijkstra's algorithm.
  # `graph`: Hash, node_id => Array of [neighbor_id, weight] pairs.
  # `source`: Integer node_id.
  # Returns a Hash: node_id => shortest_distance.
  def self.compute(graph, source)
    # `distances` stores the shortest distance found so far from `source` to each node.
    distances = {}
    # `pq` is the priority queue for nodes to visit, prioritized by distance.
    pq = MinPriorityQueue.new
    # `visited` tracks nodes for which the shortest path has been finalized.
    # Using a Hash as a Set: {node_id => true}.
    visited = {}

    # Initialize distance to source node as 0 and add to PQ.
    distances[source] = 0
    pq.insert(source, 0)

    while !pq.empty?
      # Extract node `u_node` with the smallest current distance.
      current_dist, u_node = pq.extract_min
      
      # If `u_node` has already been visited, its shortest path is finalized.
      # Skip this entry. This is key for correctness and efficiency.
      next if visited[u_node]
      visited[u_node] = true # Mark `u_node` as visited.

      # Iterate over neighbors `v_node` of `u_node`.
      # `(graph[u_node] || [])` handles cases where `u_node` has no outgoing edges
      # or is not a key in the `graph` hash (e.g., a sink node).
      (graph[u_node] || []).each do |neighbor_data|
        v_node, weight = neighbor_data

        # If `v_node` is already finalized, we cannot find a shorter path to it
        # through `u_node` because Dijkstra processes nodes in order of increasing distance.
        next if visited[v_node]

        new_dist = current_dist + weight

        # If this path to `v_node` is shorter than any known path:
        # `(distances[v_node] || Float::INFINITY)` handles nodes not yet in `distances`
        # by treating their current known distance as infinity.
        known_dist_to_v = distances[v_node] || Float::INFINITY
        if new_dist < known_dist_to_v
          distances[v_node] = new_dist
          # If `v_node` is already in PQ, update its priority. Otherwise, insert it.
          if pq.has_node?(v_node)
            pq.decrease_key(v_node, new_dist)
          else
            pq.insert(v_node, new_dist)
          end
        end
      end
    end

    distances
  end
end