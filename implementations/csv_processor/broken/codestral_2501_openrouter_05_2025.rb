class CsvProcessor
  def self.process(data, transformations)
    headers = data.first.split(',')
    rows = data[1..].map { |row| row.split(',').zip(headers).to_h }

    filtered_data = transformations[:filter] ? rows.select(&transformations[:filter]) : rows
    selected_data = filtered_data.map { |row| row.select { |k, _| transformations[:select].include?(k) } }

    aggregations = transformations[:aggregate] ? transformations[:aggregate].transform_values { |agg| agg.call(filtered_data) } : {}

    { filtered_data: selected_data, aggregations: aggregations }
  end
end