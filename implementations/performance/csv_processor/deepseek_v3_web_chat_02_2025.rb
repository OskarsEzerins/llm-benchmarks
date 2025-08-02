class CsvProcessor
  def self.process(data, transformations)
    headers = data.first.split(',')
    rows = data[1..-1]

    processed_data = []
    aggregations = {}

    rows.each do |row|
      values = row.split(',')
      row_hash = headers.zip(values).to_h

      if transformations[:filter] && !transformations[:filter].call(row_hash)
        next
      end

      if transformations[:select]
        row_hash = row_hash.select { |k, _| transformations[:select].include?(k) }
      end

      processed_data << row_hash
    end

    if transformations[:aggregate]
      transformations[:aggregate].each do |key, agg_func|
        aggregations[key] = agg_func.call(processed_data)
      end
    end

    { filtered_data: processed_data, aggregations: aggregations }
  end
end
