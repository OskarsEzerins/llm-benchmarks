require 'benchmark'

class GraphShortestPathsBenchmark
  def self.run(implementation_path)
    require_relative implementation_path

    srand(42)
    n = 100_00
    graph = {}
    n.times do |node|
      graph[node] = []
      rand(100..1000).times do
        neighbor = rand(n)
        neighbor = (neighbor == node ? (neighbor + 1) % n : neighbor)
        weight = rand(100..1000)
        graph[node] << [neighbor, weight]
      end
    end

    source = 0

    time = Benchmark.realtime do
      GraphShortestPaths.compute(graph, source)
    end

    time.round(4)
  end
end
