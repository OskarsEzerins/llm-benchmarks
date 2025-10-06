class CsvProcessor
  def self.process(data, transformations)
    headers = data[0].split(',')
    chunk_size = 1000
    filtered_rows = []
    aggregations = {}

    data[1..].each_slice(chunk_size) do |chunk|
      chunk.each do |line|
        row = parse_row(headers, line)
        next if transformations[:filter] && !transformations[:filter].call(row)

        filtered_row = {}
        if transformations[:select]
          transformations[:select].each { |col| filtered_row[col] = row[col] }
        else
          filtered_row = row
        end
        filtered_rows << filtered_row
      end
    end

    if transformations[:aggregate]
      transformations[:aggregate].each do |key, func|
        aggregations[key] = func.call(filtered_rows)
      end
    end

    { filtered_data: filtered_rows, aggregations: aggregations }
  end

  private

  def self.parse_row(headers, line)
    values = line.split(',')
    headers.zip(values).to_h
  end
end