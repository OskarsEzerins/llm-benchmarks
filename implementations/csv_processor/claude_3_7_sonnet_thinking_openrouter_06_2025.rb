class CsvProcessor
  def self.process(data, transformations, chunk_size = 100)
    headers = parse_row(data.first)
    
    filtered_data = []
    filtered_for_agg = []
    
    # Process data in chunks
    data[1..-1].each_slice(chunk_size) do |chunk|
      chunk.each do |row|
        values = parse_row(row)
        row_hash = headers.zip(values).to_h
        
        # Apply filter
        next if transformations[:filter] && !transformations[:filter].call(row_hash)
        
        # Keep the complete row for aggregation
        filtered_for_agg << row_hash
        
        # Apply select for display
        if transformations[:select]
          row_hash = transformations[:select].each_with_object({}) do |key, new_row|
            new_row[key] = row_hash[key] if row_hash.key?(key)
          end
        end
        
        filtered_data << row_hash
      end
    end
    
    result = { filtered_data: filtered_data }
    
    # Compute aggregations
    if transformations[:aggregate]
      aggregations = {}
      transformations[:aggregate].each do |key, agg_func|
        aggregations[key] = agg_func.call(filtered_for_agg)
      end
      result[:aggregations] = aggregations
    end
    
    result
  end
  
  def self.parse_row(row)
    row.strip.split(',')
  end
  
  private_class_method :parse_row
end