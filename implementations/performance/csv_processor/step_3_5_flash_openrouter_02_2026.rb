class CsvProcessor
  def self.process(input_data, transformations)
    return { filtered_data: [], aggregations: {} } if input_data.empty?

    headers = input_data.first.split(',')
    filtered_rows = []
    aggregate_data = transformations[:aggregate] ? [] : nil

    input_data[1..].each do |line|
      values = line.split(',')
      row = Hash[headers.zip(values)]

      next if transformations[:filter] && !transformations[:filter].call(row)

      if transformations[:select]
        filtered_rows << row.select { |k| transformations[:select].include?(k) }
      else
        filtered_rows << row
      end

      aggregate_data << row if aggregate_data
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, func|
        aggregations[key] = func.call(aggregate_data)
      end
    end

    { filtered_data: filtered_rows, aggregations: aggregations }
  end
end