class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations = {})
    new(data, transformations).process
  end

  def initialize(data, transformations)
    @data = data
    @transformations = transformations
    @headers = nil
  end

  def process
    result = {
      filtered_data: [],
      aggregations: {}
    }

    all_filtered_rows = []
    
    process_in_chunks do |chunk|
      filtered_chunk = apply_filter(chunk)
      selected_chunk = apply_select(filtered_chunk)
      all_filtered_rows.concat(filtered_chunk)
      result[:filtered_data].concat(selected_chunk)
    end

    result[:aggregations] = apply_aggregations(all_filtered_rows)
    
    result
  end

  private

  def process_in_chunks
    @headers = parse_line(@data.first)
    
    lines = @data.drop(1)
    lines.each_slice(CHUNK_SIZE) do |chunk_lines|
      chunk = chunk_lines.map { |line| line_to_hash(line) }
      yield(chunk)
    end
  end

  def apply_filter(rows)
    return rows unless @transformations[:filter]
    
    rows.select { |row| @transformations[:filter].call(row) }
  end

  def apply_select(rows)
    return rows unless @transformations[:select]
    
    selected_fields = @transformations[:select]
    rows.map do |row|
      selected_fields.each_with_object({}) do |field, selected_row|
        selected_row[field] = row[field] if row.key?(field)
      end
    end
  end

  def apply_aggregations(rows)
    return {} unless @transformations[:aggregate]
    
    @transformations[:aggregate].each_with_object({}) do |(name, agg_func), result|
      result[name] = agg_func.call(rows)
    end
  end

  def line_to_hash(line)
    values = parse_line(line)
    @headers.zip(values).to_h
  end

  def parse_line(line)
    line.split(',').map(&:strip)
  end
end