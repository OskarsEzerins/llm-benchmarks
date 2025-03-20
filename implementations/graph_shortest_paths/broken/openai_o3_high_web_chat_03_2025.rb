class GraphShortestPaths
  def self.compute(graph, source)
    dist = { source => 0 }
    pq = PriorityQueue.new
    pq.push(source, 0)
    until pq.empty?
      node, d = pq.pop
      next if d > dist[node]
      if graph[node]
        graph[node].each do |nbr, w|
          nd = d + w
          if !dist.key?(nbr) || nd < dist[nbr]
            dist[nbr] = nd
            pq.push(nbr, nd)
          end
        end
      end
    end
    dist
  end

  class PriorityQueue
    def initialize
      @heap = []
      @positions = {}
    end

    def empty?
      @heap.empty?
    end

    def push(node, priority)
      if @positions.key?(node)
        index = @positions[node]
        if priority < @heap[index][0]
          @heap[index][0] = priority
          sift_up(index)
        end
      else
        index = @heap.size
        @heap << [priority, node]
        @positions[node] = index
        sift_up(index)
      end
    end

    def pop
      smallest = @heap[0]
      last = @heap.pop
      @positions.delete(smallest[1])
      if !@heap.empty?
        @heap[0] = last
        @positions[last[1]] = 0
        sift_down(0)
      end
      smallest
    end

    private

    def sift_up(idx)
      while idx > 0
        parent = (idx - 1) >> 1
        if @heap[idx][0] < @heap[parent][0]
          @heap[idx], @heap[parent] = @heap[parent], @heap[idx]
          @positions[@heap[idx][1]] = idx
          @positions[@heap[parent][1]] = parent
          idx = parent
        else
          break
        end
      end
    end

    def sift_down(idx)
      n = @heap.size
      loop do
        left = (idx << 1) + 1
        right = left + 1
        smallest = idx
        smallest = left if left < n && @heap[left][0] < @heap[smallest][0]
        smallest = right if right < n && @heap[right][0] < @heap[smallest][0]
        break if smallest == idx
        @heap[idx], @heap[smallest] = @heap[smallest], @heap[idx]
        @positions[@heap[idx][1]] = idx
        @positions[@heap[smallest][1]] = smallest
        idx = smallest
      end
    end
  end
end
