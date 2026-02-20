module GraphShortestPaths
  INF = (1 << 60)

  SHIFT = 20
  MASK = (1 << SHIFT) - 1

  class MinHeap
    def initialize
      @heap = []
    end

    def push(val)
      heap = @heap
      heap << val
      i = heap.size - 1
      while i > 0
        parent = (i - 1) >> 1
        break if heap[parent] <= val
        heap[i] = heap[parent]
        i = parent
      end
      heap[i] = val
      nil
    end

    def pop
      heap = @heap
      return nil if heap.empty?
      min = heap[0]
      last = heap.pop
      if !heap.empty?
        i = 0
        len = heap.size
        while (child = (i << 1) + 1) < len
          right = child + 1
          child = right if right < len && heap[right] < heap[child]
          break if last <= heap[child]
          heap[i] = heap[child]
          i = child
        end
        heap[i] = last
      end
      min
    end

    def empty?
      @heap.empty?
    end
  end

  def self.compute(graph, source)
    distances = Hash.new(INF)
    visited = {}

    heap = MinHeap.new
    heap.push((0 << SHIFT) | source)
    distances[source] = 0

    shift_local = SHIFT
    mask_local = MASK
    dist_map = distances
    vis = visited
    g = graph

    while !heap.empty?
      combined = heap.pop
      cur_dist = combined >> shift_local
      node = combined & mask_local

      next unless cur_dist == dist_map[node]
      next if vis[node]

      vis[node] = true

      edges = g[node]
      unless edges.nil?
        edges.each do |neighbor, weight|
          alt = cur_dist + weight
          if alt < dist_map[neighbor]
            dist_map[neighbor] = alt
            heap.push((alt << shift_local) | neighbor)
          end
        end
      end
    end

    distances
  end
end