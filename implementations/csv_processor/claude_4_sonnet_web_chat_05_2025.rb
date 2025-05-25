class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations = {})
    return { filtered_data: [], aggregations: {} } if data.empty?
    
    headers = parse_csv_row(data[0])
    result = { filtered_data: [], aggregations: {} }
    all_rows = []
    
    # Process data in chunks
    (1...data.length).each_slice(CHUNK_SIZE) do |chunk_indices|
      chunk_rows = chunk_indices.map do |i|
        values = parse_csv_row(data[i])
        Hash[headers.zip(values)]
      end
      
      # Apply filter if provided
      if transformations[:filter]
        chunk_rows = chunk_rows.select(&transformations[:filter])
      end
      
      # Apply column selection if provided
      if transformations[:select]
        chunk_rows = chunk_rows.map do |row|
          row.select { |key, _| transformations[:select].include?(key) }
        end
      end
      
      result[:filtered_data].concat(chunk_rows)
      all_rows.concat(chunk_rows) if transformations[:aggregate]
    end
    
    # Apply aggregations if provided
    if transformations[:aggregate] && !all_rows.empty?
      transformations[:aggregate].each do |key, func|
        result[:aggregations][key] = func.call(all_rows)
      end
    end
    
    result
  end
  
  private
  
  def self.parse_csv_row(row)
    result = []
    current_field = ""
    in_quotes = false
    i = 0
    
    while i < row.length
      char = row[i]
      
      case char
      when '"'
        if in_quotes && i + 1 < row.length && row[i + 1] == '"'
          current_field += '"'
          i += 1
        else
          in_quotes = !in_quotes
        end
      when ','
        if in_quotes
          current_field += char
        else
          result << current_field.strip
          current_field = ""
        end
      else
        current_field += char
      end
      
      i += 1
    end
    
    result << current_field.strip
    result
  end
end