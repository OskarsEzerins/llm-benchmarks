class CsvProcessor
def self.process(input_data, transformations)
headers = input_data.first.split(',').map(&:strip )
filtered_rows = []
filtered_data = []

input_data[1..-1].each do |line|
  next if line.strip.empty?
  fields = line.split(',').map(&:strip)
  row = headers.each_with_index.each_with_object({}) do |(header, index), hash|
    hash[header] = fields[index]
  end

  if transformations[:filter] && !transformations[:filter].call(row)
    next
  end

  filtered_rows << row

  selected = if transformations[:select]
    transformations[:select].each_with_object({}) do |key, h|
      h[key] = row[key]
    end
  else
    row.dup
  end
  filtered_data << selected
end

aggregations = transformations[:aggregate]&.each_with_object({}) do |(key, agg), h|
  h[key] = agg.call(filtered_rows)
end || {}

{ filtered_data: filtered_data, aggregations: aggregations }

end
end
