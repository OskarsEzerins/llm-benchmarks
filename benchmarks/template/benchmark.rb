require 'benchmark'

# NOTE: correct `LruCacheBenchmark``, wrong `LRUCacheBenchmark``
class TemplateBenchmark
  def self.run(implementation_path)
    require_relative implementation_path

    # e.g. SomeClassFromImplementation.some_method, etc.
  end
end
