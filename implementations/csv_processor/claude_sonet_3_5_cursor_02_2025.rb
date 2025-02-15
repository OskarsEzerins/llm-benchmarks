class CsvProcessor
  class << self
    def process(data, transformations, chunk_size: 1000)
      new(data, transformations, chunk_size).process
    end
  end

  def initialize(data, transformations, chunk_size)
    @headers = parse_headers(data.first)
    @data = data.drop(1)
    @transformations = transformations
    @chunk_size = chunk_size
  end

  def process
    chunks = @data.each_slice(@chunk_size)
    processed_data = []
    row_accumulator = []

    chunks.each do |chunk|
      chunk_rows = chunk.map { |row| parse_row(row) }

      if @transformations[:filter]
        chunk_rows = chunk_rows.select { |row| @transformations[:filter].call(row) }
      end

      if @transformations[:select]
        chunk_rows = chunk_rows.map { |row| select_fields(row) }
      end

      row_accumulator.concat(chunk_rows)
      processed_data.concat(chunk_rows)
    end

    {
      filtered_data: processed_data,
      aggregations: process_aggregations(row_accumulator)
    }
  end

  private

  def parse_headers(header_row)
    header_row.strip.split(',')
  end

  def parse_row(row)
    values = row.strip.split(',')
    Hash[@headers.zip(values)]
  end

  def select_fields(row)
    @transformations[:select].each_with_object({}) do |field, selected|
      selected[field] = row[field] if row.key?(field)
    end
  end

  def process_aggregations(rows)
    return {} unless @transformations[:aggregate]

    @transformations[:aggregate].transform_values do |aggregation_func|
      aggregation_func.call(rows)
    end
  end
end
