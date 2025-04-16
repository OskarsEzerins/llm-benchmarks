class CsvProcessor
  def self.process(data, transformations, chunk_size: 1000)
    return { filtered_data: [], aggregations: {} } if data.empty?

    headers = parse_line(data.first)
    filtered_rows = []
    aggregation_rows = []

    data_enum = data.drop(1).each_slice(chunk_size)

    data_enum.each do |chunk|
      chunk.each do |line|
        row = row_hash(parse_line(line), headers)
        next if transformations[:filter] && !transformations[:filter].call(row)

        aggregation_rows << row
        if transformations[:select]
          filtered_rows << select_keys(row, transformations[:select])
        else
          filtered_rows << row
        end
      end
    end

    aggs = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, func|
        aggs[key] = func.call(aggregation_rows)
      end
    end

    { filtered_data: filtered_rows, aggregations: aggs }
  end

  private_class_method def self.parse_line(line)
    # Simple CSV parsing (no quotes, no escapes)
    line.split(",")
  end

  private_class_method def self.row_hash(values, headers)
    h = {}
    headers.each_with_index { |k, i| h[k] = values[i] }
    h
  end

  private_class_method def self.select_keys(row, keys)
    result = {}
    keys.each { |k| result[k] = row[k] if row.key?(k) }
    result
  end
end
