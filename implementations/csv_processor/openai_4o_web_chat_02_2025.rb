class CsvProcessor
  def self.process(data, transformations, chunk_size: 100)
    new(data, transformations, chunk_size).process
  end

  def initialize(data, transformations, chunk_size)
    @headers = data.first.split(",")
    @rows = data[1..]
    @transformations = transformations
    @chunk_size = chunk_size
  end

  def process
    filtered_data = []
    aggregation_data = []

    @rows.each_slice(@chunk_size) do |chunk|
      parsed_chunk = chunk.map { |line| parse_line(line) }
      filtered_chunk = apply_filter(parsed_chunk)
      filtered_data.concat(select_columns(filtered_chunk))
      aggregation_data.concat(filtered_chunk)
    end

    {
      filtered_data: filtered_data,
      aggregations: apply_aggregations(aggregation_data)
    }
  end

  private

  def parse_line(line)
    values = line.split(",")
    @headers.zip(values).to_h
  end

  def apply_filter(rows)
    return rows unless @transformations[:filter]
    rows.select { |row| @transformations[:filter].call(row) }
  end

  def select_columns(rows)
    return rows unless @transformations[:select]
    rows.map { |row| row.slice(*@transformations[:select]) }
  end

  def apply_aggregations(rows)
    return {} unless @transformations[:aggregate]
    @transformations[:aggregate].transform_values { |agg_proc| agg_proc.call(rows) }
  end
end
