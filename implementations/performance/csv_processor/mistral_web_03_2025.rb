class CsvProcessor
  def self.process(data, transformations)
    headers = data.first.split(',')
    rows = data[1..].map { |row| row.split(',') }

    filtered_data = rows.lazy.map { |row| headers.zip(row).to_h }
                         .filter(&transformations[:filter])
                         .map { |row| row.select { |key, _| transformations[:select].include?(key) } }
                         .to_a

    aggregations = {}
    transformations[:aggregate].each do |key, func|
      aggregations[key] = func.call(rows.map { |row| headers.zip(row).to_h })
    end

    { filtered_data: filtered_data, aggregations: aggregations }
  end
end
