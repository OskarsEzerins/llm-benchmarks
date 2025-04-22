class CsvProcessor
  def self.process(data, transformations = {})
    headers = parse_headers(data.first)
    rows = parse_rows(data.drop(1), headers)

    # Apply filter transformation if provided
    filtered_rows = transformations[:filter] ? rows.filter { |row| transformations[:filter].call(row) } : rows

    # Apply select transformation if provided
    if transformations[:select]
      filtered_rows = filtered_rows.map do |row|
        row.select { |key, _| transformations[:select].include?(key) }
      end
    end

    # Calculate aggregations if provided
    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |name, aggregation_function|
        aggregations[name] = aggregation_function.call(rows)
      end
    end

    {
      filtered_data: filtered_rows,
      aggregations: aggregations
    }
  end

  private

  def self.parse_headers(header_row)
    header_row.split(',').map(&:strip)
  end

  def self.parse_rows(data_rows, headers)
    data_rows.each_with_object([]) do |row_str, result|
      values = row_str.split(',').map(&:strip)
      row_hash = {}

      headers.each_with_index do |header, index|
        row_hash[header] = values[index] if index < values.length
      end

      result << row_hash
    end
  end

  # Method to process data in chunks
  def self.process_in_chunks(data, transformations = {}, chunk_size = 1000)
    result = {
      filtered_data: [],
      aggregations: {}
    }

    headers = parse_headers(data.first)

    # Process data in chunks
    data.drop(1).each_slice(chunk_size).each do |chunk|
      chunk_rows = parse_rows(chunk, headers)
      chunk_result = process_chunk(chunk_rows, transformations)

      result[:filtered_data].concat(chunk_result[:filtered_data])

      # Combine aggregations (this is simplified and might need adjustment based on specific aggregation logic)
      if result[:aggregations].empty?
        result[:aggregations] = chunk_result[:aggregations]
      else
        # This is a placeholder for proper aggregation combination logic
        # Actual implementation would depend on specific aggregation requirements
      end
    end

    # Finalize aggregations if needed
    # This would recalculate aggregations based on all data if necessary

    result
  end

  def self.process_chunk(rows, transformations)
    # Similar to the main process method, but works on a chunk of data
    filtered_rows = transformations[:filter] ? rows.filter { |row| transformations[:filter].call(row) } : rows

    if transformations[:select]
      filtered_rows = filtered_rows.map do |row|
        row.select { |key, _| transformations[:select].include?(key) }
      end
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |name, aggregation_function|
        aggregations[name] = aggregation_function.call(rows)
      end
    end

    {
      filtered_data: filtered_rows,
      aggregations: aggregations
    }
  end
end
