require 'tty-prompt'

class BenchmarkTypeSelectorService
  BENCHMARK_TYPE_OPTIONS = [
    { name: 'All benchmark types', value: :all_types },
    { name: 'Performance benchmarks (speed & efficiency)', value: :performance },
    { name: 'Program fixer benchmarks (fix broken code)', value: :program_fixer }
  ].freeze

  def initialize
    @prompt = TTY::Prompt.new
  end

  def select
    @prompt.select(
      "\nSelect benchmark type for new implementations:",
      BENCHMARK_TYPE_OPTIONS,
      per_page: 20,
      filter: true,
      cycle: true,
      filter_hint: '(Start typing to filter)'
    )
  end
end
