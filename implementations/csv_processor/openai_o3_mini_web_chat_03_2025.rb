class CsvProcessor
  CHUNK_SIZE = 100

  def self.process(data, transformations)
    headers = data.first.strip.split(',')
    filtered_rows = []
    aggregation_rows = []
    rows = data[1..-1]

    rows.each_slice(CHUNK_SIZE) do |chunk|
      chunk.each do |line|
        values = line.strip.split(',')
        row = headers.zip(values).to_h
        if transformations[:filter]
          next unless transformations[:filter].call(row)
        end
        aggregation_rows << row.dup
        if transformations[:select]
          row = row.select { |key, _| transformations[:select].include?(key) }
        end
        filtered_rows << row
      end
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, agg_proc|
        aggregations[key] = agg_proc.call(aggregation_rows)
      end
    end

    { filtered_data: filtered_rows, aggregations: aggregations }
  end
end
