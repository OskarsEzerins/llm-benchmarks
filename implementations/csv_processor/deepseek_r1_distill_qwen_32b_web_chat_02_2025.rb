class CsvProcessor
  def self.process(input_data, transformations)
    return { filtered_data: [], aggregations: {} } if input_data.empty?

    chunk_size = 1000
    header = input_data.first.split(',')
    data_rows = input_data[1..-1]
    filtered_rows = []

    data_rows.each_slice(chunk_size) do |chunk|
      chunk.each do |row|
        cells = row.split(',')
        next if cells.size != header.size  # Skip malformed rows

        row_hash = Hash[header.zip(cells)]
        # Apply filter if present
        if transformations[:filter] && !transformations[:filter].call(row_hash)
          next
        end
        filtered_rows << row_hash
      end
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, lambda|
        aggregations[key] = lambda.call(filtered_rows)
      end
    end

    filtered_data = if transformations[:select]
                      filtered_rows.map do |row|
                        selected = {}
                        transformations[:select].each do |col|
                          selected[col] = row[col]
                        end
                        selected
                      end
                    else
                      filtered_rows
                    end

    { filtered_data: filtered_data, aggregations: aggregations }
  end
end
