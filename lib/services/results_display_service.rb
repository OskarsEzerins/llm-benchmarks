require 'time'

class ResultsDisplayService
  def self.display(results, current_implementation)
    new(results, current_implementation).display
  end

  def initialize(results, current_implementation)
    @results = results
    @current_implementation = current_implementation
  end

  def display
    display_rankings_table
    display_details_table if @current_implementation
  end

  private

  def display_rankings_table
    table = Terminal::Table.new do |t|
      t.title = "LRU Cache Implementation Benchmarks"
      t.headings = ['Rank', 'Implementation', 'Time (s)', 'Date', 'Status']

      @results.each_with_index do |result, index|
        status = result['implementation'] == @current_implementation ? '🆕' : ' '
        t.add_row [
          index + 1,
          result['implementation'],
          result['metrics']['execution_time'],
          format_time(result['timestamp']),
          status
        ]
      end
    end

    puts "\n#{table}"
  end

  def display_details_table
    current_result = @results.find { |r| r['implementation'] == @current_implementation }
    puts "\nLatest Run Details:"
    details_table = Terminal::Table.new do |t|
      t.style = { width: 80 }
      t.add_row ['Implementation', @current_implementation]
      t.add_separator
      current_result['metrics'].each do |metric, value|
        next if metric == 'execution_time'
        t.add_row [metric.split('_').map(&:capitalize).join(' '), value]
      end
    end
    puts details_table
  end

  def format_time(timestamp)
    Time.parse(timestamp).strftime("%Y-%m-%d %H:%M:%S")
  end
end
