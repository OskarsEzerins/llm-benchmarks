require 'csv'

class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations = {})
    headers = CSV.parse_line(data.first)
    filtered_rows = []
    selected_rows = []

    data[1..-1].each_slice(CHUNK_SIZE) do |slice|
      slice.each do |line|
        values = CSV.parse_line(line)
        row = headers.zip(values).to_h

        if transformations[:filter].nil? || transformations[:filter].call(row)
          filtered_rows << row
          if transformations[:select]
            selected_rows << row.select { |k, _| transformations[:select].include?(k) }
          else
            selected_rows << row
          end
        end
      end
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |name, func|
        aggregations[name] = func.call(filtered_rows)
      end
    end

    { filtered_data: selected_rows, aggregations: aggregations }
  end
end
