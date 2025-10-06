class CsvProcessor
  def self.process(input_data, transformations)
    new(input_data, transformations).process
  end

  def initialize(input_data, transformations)
    @input_data = input_data
    @transformations = transformations
    @headers = input_data.first.split(',')
  end

  def process
    result = { filtered_data: [], aggregations: {} }
    
    process_in_chunks do |chunk|
      filtered_chunk = apply_filters(chunk)
      selected_chunk = apply_select(filtered_chunk)
      result[:filtered_data].concat(selected_chunk)
    end
    
    result[:aggregations] = apply_aggregations(result[:filtered_data]) if @transformations[:aggregate]
    result
  end

  private

  def process_in_chunks(&block)
    chunk_size = 1000
    chunk = []
    
    @input_data[1..-1].each do |row|
      parsed_row = parse_row(row)
      chunk << parsed_row
      
      if chunk.size >= chunk_size
        yield chunk
        chunk = []
      end
    end
    
    yield chunk unless chunk.empty?
  end

  def parse_row(row)
    values = row.split(',')
    @headers.each_with_index.each_with_object({}) do |(header, index), hash|
      hash[header] = values[index]
    end
  end

  def apply_filters(chunk)
    return chunk unless @transformations[:filter]
    
    chunk.select { |row| @transformations[:filter].call(row) }
  end

  def apply_select(chunk)
    return chunk unless @transformations[:select]
    
    chunk.map do |row|
      row.select { |key, _| @transformations[:select].include?(key) }
    end
  end

  def apply_aggregations(data)
    @transformations[:aggregate].each_with_object({}) do |(key, agg_func), result|
      result[key] = agg_func.call(data)
    end
  end
end