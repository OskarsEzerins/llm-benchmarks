class CsvProcessor
  def self.process(data, transformations = {})
    processor = new(data)
    processor.apply_transformations(transformations)
  end

  def initialize(data, chunk_size = 1000)
    @data = data
    @chunk_size = chunk_size
    @headers = parse_headers
  end

  def apply_transformations(transformations)
    result = { filtered_data: [], aggregations: {} }
    
    filtered_rows = []
    
    each_chunk do |chunk|
      chunk_rows = chunk.map { |row| parse_row(row) }
      
      if transformations[:filter]
        chunk_rows = chunk_rows.select(&transformations[:filter])
      end
      
      if transformations[:select]
        chunk_rows = chunk_rows.map do |row|
          row.select { |key, _| transformations[:select].include?(key) }
        end
      end
      
      filtered_rows.concat(chunk_rows)
      result[:filtered_data].concat(chunk_rows)
    end
    
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, aggregator|
        result[:aggregations][key] = aggregator.call(filtered_rows)
      end
    end
    
    result
  end

  private

  def parse_headers
    return [] if @data.empty?
    @data[0].split(',').map(&:strip)
  end

  def parse_row(row_string)
    values = row_string.split(',').map(&:strip)
    @headers.zip(values).to_h
  end

  def each_chunk
    return enum_for(:each_chunk) unless block_given?
    
    data_rows = @data[1..-1] || []
    
    data_rows.each_slice(@chunk_size) do |chunk|
      yield chunk
    end
  end
end