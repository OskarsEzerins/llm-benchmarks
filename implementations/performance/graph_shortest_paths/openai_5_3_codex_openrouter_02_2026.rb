# frozen_string_literal: true

class GraphShortestPaths
  class MinHeap
    attr_reader :last_dist, :last_node

    def initialize(capacity = 16)
      @dists = Array.new(capacity)
      @nodes = Array.new(capacity)
      @size = 0
      @last_dist = nil
      @last_node = nil
    end

    def push(dist, node)
      size = @size
      dists = @dists
      nodes = @nodes

      if size >= dists.length
        new_len = (size << 1) + 1
        dists[new_len - 1] = nil
        nodes[new_len - 1] = nil
      end

      i = size
      while i > 0
        p = (i - 1) >> 1
        pd = dists[p]
        break if pd <= dist

        dists[i] = pd
        nodes[i] = nodes[p]
        i = p
      end

      dists[i] = dist
      nodes[i] = node
      @size = size + 1
      nil
    end

    def pop
      size = @size
      return false if size == 0

      dists = @dists
      nodes = @nodes

      min_dist = dists[0]
      min_node = nodes[0]

      size -= 1
      if size > 0
        last_dist = dists[size]
        last_node = nodes[size]

        i = 0
        half = size >> 1

        while i < half
          l = (i << 1) + 1
          r = l + 1

          c = l
          cd = dists[l]

          if r < size
            rd = dists[r]
            if rd < cd
              c = r
              cd = rd
            end
          end

          break if cd >= last_dist

          dists[i] = cd
          nodes[i] = nodes[c]
          i = c
        end

        dists[i] = last_dist
        nodes[i] = last_node
      end

      @size = size
      @last_dist = min_dist
      @last_node = min_node
      true
    end
  end

  def self.compute(graph, source)
    distances = {}
    distances[source] = 0

    heap = MinHeap.new(graph.size + 1)
    heap.push(0, source)

    while heap.pop
      d = heap.last_dist
      u = heap.last_node

      next unless distances[u] == d

      edges = graph[u]
      next if edges.nil? || edges.empty?

      i = 0
      while i < edges.length
        edge = edges[i]
        v = edge[0]
        nd = d + edge[1]

        cur = distances[v]
        if cur.nil? || nd < cur
          distances[v] = nd
          heap.push(nd, v)
        end

        i += 1
      end
    end

    distances
  end
end