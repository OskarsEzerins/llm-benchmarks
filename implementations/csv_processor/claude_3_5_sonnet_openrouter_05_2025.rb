class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations)
    new(data, transformations).process
  end

  def initialize(data, transformations)
    @data = data
    @transformations = transformations
    @headers = []
    @results = {
      filtered_data: [],
      aggregations: {}
    }
  end

  def process
    parse_headers
    process_chunks
    calculate_aggregations
    @results
  end

  private

  def parse_headers
    @headers = @data[0].split(',').map(&:strip)
  end

  def process_chunks
    chunks = @data[1..].each_slice(CHUNK_SIZE)
    chunks.each { |chunk| process_chunk(chunk) }
  end

  def process_chunk(chunk)
    rows = chunk.map { |line| parse_row(line) }
    
    filtered_rows = if @transformations[:filter]
      rows.select { |row| @transformations[:filter].call(row) }
    else
      rows
    end

    selected_rows = if @transformations[:select]
      filtered_rows.map { |row| select_fields(row) }
    else
      filtered_rows
    end

    @results[:filtered_data].concat(selected_rows)
  end

  def parse_row(line)
    values = line.split(',').map(&:strip)
    Hash[@headers.zip(values)]
  end

  def select_fields(row)
    @transformations[:select].each_with_object({}) do |field, selected|
      selected[field] = row[field] if row.key?(field)
    end
  end

  def calculate_aggregations
    return unless @transformations[:aggregate]

    @transformations[:aggregate].each do |key, aggregator|
      @results[:aggregations][key] = aggregator.call(@results[:filtered_data])
    end
  end
end