class CsvProcessor
  DEFAULT_CHUNK_SIZE = 1000

  def self.process(input_data, transformations = {})
    return { filtered_data: [], aggregations: {} } if input_data.empty?

    headers = input_data.first.split(',').map(&:strip)
    all_rows = []
    
    (1...input_data.length).step(DEFAULT_CHUNK_SIZE) do |i|
      chunk = input_data[i...[i + DEFAULT_CHUNK_SIZE, input_data.length].min]
      parsed_chunk = chunk.map do |line|
        values = line.split(',').map(&:strip)
        headers.zip(values).to_h
      end
      all_rows.concat(parsed_chunk)
    end

    filtered_rows = all_rows
    if transformations[:filter]
      filtered_rows = all_rows.select(&transformations[:filter])
    end

    result_data = filtered_rows
    if transformations[:select]
      selected_keys = transformations[:select]
      result_data = filtered_rows.map do |row|
        row.select { |key, _| selected_keys.include?(key) }
      end
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, agg_func|
        aggregations[key] = agg_func.call(filtered_rows)
      end
    end

    {
      filtered_data: result_data,
      aggregations: aggregations
    }
  end
end