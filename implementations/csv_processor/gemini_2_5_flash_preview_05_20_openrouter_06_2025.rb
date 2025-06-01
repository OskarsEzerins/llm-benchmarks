class CsvProcessor
  CHUNK_SIZE = 1000 # Define a reasonable chunk size

  def self.process(csv_data, transformations)
    header, *rows_data = csv_data
    headers = header.split(',')
    
    transformed_results = []
    aggregations_data = {}
    
    # Initialize aggregation accumulators
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, _|
        aggregations_data[key] = []
      end
    end

    rows_data.each_slice(CHUNK_SIZE) do |chunk|
      chunk.each do |row_str|
        values = row_str.split(',')
        row_hash = {}
        headers.each_with_index do |h, i|
          row_hash[h] = values[i]
        end

        # Filtering
        if transformations[:filter]
          next unless transformations[:filter].call(row_hash)
        end

        # Selection
        selected_row = {}
        if transformations[:select]
          transformations[:select].each do |field|
            selected_row[field] = row_hash[field]
          end
        else
          selected_row = row_hash # If no select, keep all fields
        end
        transformed_results << selected_row

        # Aggregation data accumulation
        if transformations[:aggregate]
          transformations[:aggregate].each do |key, _|
            aggregations_data[key] << row_hash
          end
        end
      end
    end

    # Perform final aggregations
    final_aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, func|
        final_aggregations[key] = func.call(aggregations_data[key])
      end
    end

    {
      filtered_data: transformed_results,
      aggregations: final_aggregations
    }
  end
end