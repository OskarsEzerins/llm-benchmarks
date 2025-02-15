class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations)
    header_line = data.first
    headers = header_line.split(',')
    filtered_rows = []
    filtered_rows_enum = Enumerator.new do |yielder|
      data[1..-1].each_slice(CHUNK_SIZE) do |chunk|
        chunk.each do |line|
          row = line.split(',').each_with_index.each_with_object({}) { |(value, idx), h| h[headers[idx]] = value }
          if transformations[:filter].nil? || transformations[:filter].call(row)
            row = row.slice(*transformations[:select]) if transformations[:select]
            yielder << row
          end
        end
      end
    end

    filtered_rows = filtered_rows_enum.to_a
    aggregations = {}

    if transformations[:aggregate]
      transformations[:aggregate].each do |key, aggregator|
        aggregations[key] = aggregator.call(filtered_rows)
      end
    end

    { filtered_data: filtered_rows, aggregations: aggregations }
  end
end
