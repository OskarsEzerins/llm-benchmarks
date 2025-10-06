class CsvProcessor
  def self.process(data, transformations)
    return { filtered_data: [], aggregations: {} } if data.empty?

    headers = data[0].split(',').map(&:strip)
    all_filtered = []

    data[1..-1].each do |line|
      fields = line.split(',').map(&:strip)
      next if fields.length != headers.length

      row = headers.zip(fields).to_h

      if transformations[:filter].nil? || transformations[:filter].call(row)
        all_filtered << row
      end
    end

    filtered_data = if transformations[:select]
                      all_filtered.map do |row|
                        selected = {}
                        transformations[:select].each { |col| selected[col] = row[col] }
                        selected
                      end
                    else
                      all_filtered
                    end

    aggs = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, lambda|
        aggs[key] = lambda.call(all_filtered)
      end
    end

    {
      filtered_data: filtered_data,
      aggregations: aggs
    }
  end
end