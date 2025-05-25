class CsvProcessor
  def self.process(input_data, transformations)
    new(input_data, transformations).process
  end

  def initialize(input_data, transformations)
    @input_data = input_data
    @transformations = transformations
    @chunk_size = 1000
  end

  def process
    headers = parse_headers(@input_data.first)
    rows = @input_data[1..-1]
    
    filtered_rows = []
    
    rows.each_slice(@chunk_size) do |chunk|
      chunk_rows = chunk.map { |row| parse_row(row, headers) }
      
      chunk_rows.each do |row|
        if should_include?(row)
          filtered_rows << row
        end
      end
    end
    
    selected_data = filtered_rows.map { |row| select_fields(row) }
    aggregations = calculate_aggregations(filtered_rows)
    
    {
      filtered_data: selected_data,
      aggregations: aggregations
    }
  end

  private

  def parse_headers(header_line)
    header_line.split(',').map(&:strip)
  end

  def parse_row(row_line, headers)
    values = row_line.split(',').map(&:strip)
    headers.zip(values).to_h
  end

  def should_include?(row)
    return true unless @transformations[:filter]
    @transformations[:filter].call(row)
  end

  def select_fields(row)
    return row unless @transformations[:select]
    
    selected = {}
    @transformations[:select].each do |field|
      selected[field] = row[field] if row.key?(field)
    end
    selected
  end

  def calculate_aggregations(rows)
    return {} unless @transformations[:aggregate]
    
    aggregations = {}
    @transformations[:aggregate].each do |name, calculator|
      aggregations[name] = calculator.call(rows)
    end
    aggregations
  end
end