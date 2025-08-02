class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations)
    new(data, transformations).process
  end

  def initialize(data, transformations)
    @data = data
    @transformations = transformations
    @headers = []
    @result = {
      filtered_data: [],
      aggregations: {}
    }
  end

  def process
    parse_headers
    process_chunks
    apply_aggregations
    @result
  end

  private

  def parse_headers
    @headers = @data.first.split(',').map(&:strip)
  end

  def process_chunks
    chunks = @data.drop(1).each_slice(CHUNK_SIZE)
    
    chunks.each do |chunk|
      process_chunk(chunk)
    end
  end

  def process_chunk(chunk)
    chunk.each do |line|
      row = parse_row(line)
      process_row(row) if passes_filter?(row)
    end
  end

  def parse_row(line)
    values = line.split(',').map(&:strip)
    @headers.zip(values).to_h
  end

  def passes_filter?(row)
    return true unless @transformations[:filter]
    @transformations[:filter].call(row)
  end

  def process_row(row)
    if @transformations[:select]
      row = select_fields(row)
    end
    @result[:filtered_data] << row
  end

  def select_fields(row)
    @transformations[:select].each_with_object({}) do |field, selected|
      selected[field] = row[field] if row.key?(field)
    end
  end

  def apply_aggregations
    return unless @transformations[:aggregate]
    
    @transformations[:aggregate].each do |key, aggregation|
      @result[:aggregations][key] = aggregation.call(@result[:filtered_data])
    end
  end
end