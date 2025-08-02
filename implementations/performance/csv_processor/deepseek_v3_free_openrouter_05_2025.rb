class CsvProcessor
  def self.process(data, transformations)
    headers = data.first.split(',')
    rows = data[1..-1].map { |row| Hash[headers.zip(row.split(','))] }

    if transformations[:filter]
      rows = rows.select(&transformations[:filter])
    end

    if transformations[:select]
      rows = rows.map { |row| row.select { |k, _| transformations[:include]&.include?(k) || transformations[:select].include?(k) } }
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, block|
        aggregations[key] = block.call(rows)
      end
    end

    {
      filtered_data: rows,
      aggregations: aggregations
    }
  end
end