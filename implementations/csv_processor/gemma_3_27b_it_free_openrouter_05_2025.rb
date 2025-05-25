class CsvProcessor
  def self.process(data, transformations)
    header = data.shift.split(",")
    filtered_data = []
    aggregation_data = []

    data.each do |row_string|
      row = {}
      values = row_string.split(",")
      header.each_with_index do |col, i|
        row[col] = values[i]
      end

      if transformations[:filter] && !transformations[:filter].call(row)
        next
      end

      if transformations[:select]
        row = row.select { |k, _| transformations[:select].include?(k) }
      end

      filtered_data << row
      aggregation_data << row if transformations[:aggregate]
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |agg_name, agg_func|
        aggregations[agg_name] = agg_func.call(aggregation_data)
      end
    end

    {
      filtered_data: filtered_data,
      aggregations: aggregations
    }
  end
end