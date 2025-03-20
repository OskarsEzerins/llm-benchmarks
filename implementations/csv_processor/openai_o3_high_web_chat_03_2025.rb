class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations)
    header = data.first.strip.split(',')
    filtered_data = []
    full_filtered_rows = []
    data[1..-1].each_slice(CHUNK_SIZE) do |chunk|
      chunk.each do |line|
        row = header.zip(line.strip.split(',')).to_h
        next if transformations[:filter] && !transformations[:filter].call(row)
        full_filtered_rows << row.dup
        transformed_row = transformations[:select] ? row.select { |k, _| transformations[:select].include?(k) } : row
        filtered_data << transformed_row
      end
    end
    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, agg|
        aggregations[key] = agg.call(full_filtered_rows)
      end
    end
    { filtered_data: filtered_data, aggregations: aggregations }
  end
end
