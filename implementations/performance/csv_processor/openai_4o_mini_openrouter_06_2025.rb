class CsvProcessor
  def self.process(data, transformations)
    headers = data[0].split(',')
    filtered_data = []
    aggregated_values = {}

    data[1..-1].each_slice(100) do |chunk|
      chunk.each do |row|
        row_data = Hash[headers.zip(row.split(','))]
        
        if transformations[:filter].call(row_data)
          filtered_row = transformations[:select].each_with_object({}) do |key, hash|
            hash[key] = row_data[key]
          end
          filtered_data << filtered_row
        end
      end
    end

    if transformations[:aggregate]
      transformations[:aggregate].each do |key, operation|
        aggregated_values[key] = operation.call(filtered_data)
      end
    end

    {
      filtered_data: filtered_data,
      aggregations: aggregated_values
    }
  end
end