class CsvProcessor
  def self.process(data, transformations = {})
    return { filtered_data: [], aggregations: {} } if data.empty?

    # Parse CSV data into array of hashes
    headers = data[0].split(',').map(&:strip)
    rows = data[1..-1].map do |line|
      values = line.split(',').map(&:strip)
      headers.zip(values).to_h
    end

    # Apply chunk processing for memory efficiency
    chunk_size = 1000
    filtered_data = []
    rows.each_slice(chunk_size) do |chunk|
      # Apply filter if provided
      if transformations[:filter]
        chunk = chunk.select { |row| transformations[:filter].call(row) }
      end

      # Apply select if provided
      if transformations[:select]
        chunk = chunk.map do |row|
          row.slice(*transformations[:select])
        end
      end

      filtered_data.concat(chunk)
    end

    # Calculate aggregations if provided
    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, aggregator|
        aggregations[key] = aggregator.call(rows)
      end
    end

    {
      filtered_data: filtered_data,
      aggregations: aggregations
    }
  end
end