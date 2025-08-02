class CsvProcessor
  def self.process(input_data, transformations)
    headers = input_data.first.split(',')
    result = { filtered_data: [], aggregations: {} }
    chunk_size = 100
    rows = []

    # Process data in chunks
    input_data[1..].each_slice(chunk_size) do |chunk|
      chunk.each do |line|
        row = headers.zip(line.split(',')).to_h
        rows << row if transformations[:filter].nil? || transformations[:filter].call(row)
      end
    end

    # Apply select transformation
    if transformations[:select]
      result[:filtered_data] = rows.map do |row|
        transformations[:select].each_with_object({}) do |key, selected_row|
          selected_row[key] = row[key]
        end
      end
    else
      result[:filtered_data] = rows
    end

    # Apply aggregation transformations
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, func|
        result[:aggregations][key] = func.call(rows)
      end
    end

    result
  end
end
