class CsvProcessor
  def self.process(input_data, transformations)
    new(input_data, transformations).process
  end

  def initialize(input_data, transformations)
    @input_data = input_data
    @transformations = transformations
    @headers = []
  end

  def process
    chunk_size = 1000
    filtered_rows = []
    aggregations = {}

    if @transformations[:aggregate]
      aggregate_data = []
      
      parse_chunks(chunk_size) do |rows|
        filtered = apply_filter(rows)
        selected = apply_select(filtered)
        filtered_rows.concat(selected) if @transformations[:filter] || @transformations[:select]
        
        if @transformations[:aggregate]
          aggregate_data.concat(filtered)
        end
      end
      
      if @transformations[:aggregate]
        aggregations = @transformations[:aggregate].transform_values { |fn| fn.call(aggregate_data) }
      end
    else
      parse_chunks(chunk_size) do |rows|
        filtered = apply_filter(rows)
        selected = apply_select(filtered)
        filtered_rows.concat(selected)
      end
    end

    {
      filtered_data: filtered_rows,
      aggregations: aggregations
    }
  end

  private

  def parse_chunks(chunk_size)
    rows = []
    
    @input_data.each_with_index do |line, index|
      next if index.zero? && line.include?(',')
      
      if @headers.empty?
        @headers = @input_data[0].split(',').map(&:strip)
        next if index.zero?
      end
      
      values = line.split(',').map(&:strip)
      row = {}
      
      @headers.each_with_index do |header, i|
        row[header] = values[i] if values[i]
      end
      
      rows << row
      
      if rows.length >= chunk_size
        yield rows
        rows = []
      end
    end
    
    yield rows unless rows.empty?
  end

  def apply_filter(rows)
    return rows unless @transformations[:filter]
    rows.select { |row| @transformations[:filter].call(row) }
  end

  def apply_select(rows)
    return rows unless @transformations[:select]
    rows.map { |row| row.select { |k, _| @transformations[:select].include?(k) } }
  end
end