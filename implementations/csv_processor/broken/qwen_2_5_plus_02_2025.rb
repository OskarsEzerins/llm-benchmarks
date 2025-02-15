class CsvProcessor
  def self.process(input_data, transformations)
    headers = input_data.first.split(",")
    rows = input_data[1..-1].map { |line| line.split(",").zip(headers).to_h }

    filtered_rows = rows
    if transformations[:filter]
      filtered_rows = rows.select { |row| transformations[:filter].call(row) }
    end

    selected_rows = filtered_rows
    if transformations[:select]
      selected_rows = filtered_rows.map do |row|
        transformations[:select].each_with_object({}) do |key, hash|
          hash[key] = row[key]
        end
      end
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, block|
        aggregations[key] = block.call(filtered_rows)
      end
    end

    {
      filtered_data: selected_rows,
      aggregations: aggregations
    }
  end
end
