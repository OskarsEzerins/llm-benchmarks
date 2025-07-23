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
    parse_headers
    filtered_data = []
    all_rows = []
    
    process_in_chunks do |row|
      all_rows << row
      next unless apply_filter(row)
      
      selected_row = apply_selection(row)
      filtered_data << selected_row
    end
    
    aggregations = apply_aggregations(all_rows)
    
    {
      filtered_data: filtered_data,
      aggregations: aggregations
    }
  end

  private

  def parse_headers
    @headers = @data.first.split(',').map(&:strip)
  end

  def process_in_chunks
    @data.drop(1).each_slice(CHUNK_SIZE) do |chunk|
      chunk.each do |line|
        row = parse_row(line)
        yield row if row
      end
    end
  end

  def parse_row(line)
    values = line.split(',').map(&:strip)
    return nil if values.length != @headers.length
    
    Hash[@headers.zip(values)]
  end

  def apply_filter(row)
    filter_proc = @transformations[:filter]
    return true unless filter_proc
    
    filter_proc.call(row)
  end

  def apply_selection(row)
    select_fields = @transformations[:select]
    return row unless select_fields
    
    row.select { |key, _| select_fields.include?(key) }
  end

  def apply_aggregations(rows)
    aggregate_transforms = @transformations[:aggregate]
    return {} unless aggregate_transforms
    
    result = {}
    aggregate_transforms.each do |name, agg_proc|
      result[name] = agg_proc.call(rows)
    end
    result
  end
end