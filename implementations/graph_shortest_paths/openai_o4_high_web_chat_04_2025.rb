class GraphShortestPaths
  def self.compute(graph, source)
    heap = BinaryHeap.new(graph.size)
    dist = {}
    graph.each_key { |u| dist[u] = Float::INFINITY }
    dist[source] = 0.0
    heap.push(source, 0.0)
    until heap.empty?
      u, du = heap.pop
      next unless du == dist[u]
      (graph[u] || []).each do |v, w|
        nd = du + w
        if nd < dist.fetch(v, Float::INFINITY)
          dist[v] = nd
          if heap.include?(v)
            heap.decrease_key(v, nd)
          else
            heap.push(v, nd)
          end
        end
      end
    end
    dist
  end

  class BinaryHeap
    def initialize(capacity)
      @h = Array.new(capacity + 1)
      @pos = {}
      @size = 0
    end

    def push(node, key)
      @size += 1
      @h[@size] = [node, key]
      @pos[node] = @size
      sift_up(@size)
    end

    def decrease_key(node, key)
      i = @pos[node]
      if key < @h[i][1]
        @h[i][1] = key
        sift_up(i)
      end
    end

    def pop
      return if @size.zero?
      min = @h[1]
      last = @h[@size]
      @h[1] = last
      @pos[last[0]] = 1
      @h[@size] = nil
      @pos.delete(min[0])
      @size -= 1
      sift_down(1)
      min
    end

    def include?(node)
      @pos.key?(node)
    end

    def empty?
      @size.zero?
    end

    private

    def sift_up(i)
      while i > 1
        p = i >> 1
        if @h[i][1] < @h[p][1]
          swap(i, p)
          i = p
        else
          break
        end
      end
    end

    def sift_down(i)
      while (l = i << 1) <= @size
        smallest = l
        r = l + 1
        if r <= @size && @h[r][1] < @h[l][1]
          smallest = r
        end
        if @h[smallest][1] < @h[i][1]
          swap(i, smallest)
          i = smallest
        else
          break
        end
      end
    end

    def swap(i, j)
      @h[i], @h[j] = @h[j], @h[i]
      @pos[@h[i][0]] = i
      @pos[@h[j][0]] = j
    end
  end
end
