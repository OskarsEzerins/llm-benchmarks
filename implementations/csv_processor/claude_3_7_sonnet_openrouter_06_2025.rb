class CsvProcessor
  def self.process(data, transformations, chunk_size: 1000)
    processor = new(data, transformations, chunk_size)
    processor.process
  end

  def initialize(data, transformations, chunk_size)
    @data = data
    @transformations = transformations
    @chunk_size = chunk_size
    @headers = []
    @filtered_data = []
    @aggregation_rows = []
  end

  def process
    parse_headers
    process_chunks
    
    result = {}
    result[:filtered_data] = apply_select(@filtered_data) if @transformations[:select]
    result[:aggregations] = apply_aggregations if @transformations[:aggregate]
    result
  end

  private

  def parse_headers
    @headers = @data[0].chomp.split(',')
  end

  def process_chunks
    @data[1..-1].each_slice(@chunk_size) do |chunk|
      process_chunk(chunk)
    end
  end

  def process_chunk(chunk)
    rows = chunk.map do |line|
      values = line.chomp.split(',')
      row = {}
      @headers.each_with_index do |header, index|
        row[header] = values[index]
      end
      row
    end

    if @transformations[:filter]
      filtered_rows = rows.select { |row| @transformations[:filter].call(row) }
      @filtered_data.concat(filtered_rows)
      @aggregation_rows.concat(filtered_rows) if @transformations[:aggregate]
    else
      @filtered_data.concat(rows)
      @aggregation_rows.concat(rows) if @transformations[:aggregate]
    end
  end

  def apply_select(rows)
    select_columns = @transformations[:select]
    rows.map do |row|
      selected_row = {}
      select_columns.each do |column|
        selected_row[column] = row[column] if row.key?(column)
      end
      selected_row
    end
  end

  def apply_aggregations
    aggregations = {}
    @transformations[:aggregate].each do |key, aggregation_func|
      aggregations[key] = aggregation_func.call(@aggregation_rows)
    end
    aggregations
  end
end