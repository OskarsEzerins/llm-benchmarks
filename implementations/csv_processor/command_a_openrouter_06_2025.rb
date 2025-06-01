class CsvProcessor
  def self.process(data, transformations)
    headers = data.first.split(',')
    rows = data[1..-1].map { |row| parse_row(row, headers) }

    filtered_data = apply_filter(rows, transformations[:filter])
    selected_data = apply_select(filtered_data, transformations[:select])

    aggregations = apply_aggregations(filtered_data, transformations[:aggregate])

    {
      filtered_data: selected_data,
      aggregations: aggregations
    }
  end

  private

  def self.parse_row(row, headers)
    values = row.split(',')
    headers.zip(values).to_h
  end

  def self.apply_filter(rows, filter)
    return rows unless filter

    rows.select { |row| filter.call(row) }
  end

  def self.apply_select(rows, select)
    return rows.map(&:dup) unless select

    rows.map { |row| select.map { |key| [key, row[key]] }.to_h }
  end

  def self.apply_aggregations(rows, aggregations)
    return {} unless aggregations

    aggregations.each_with_object({}) do |(name, proc), result|
      result[name] = proc.call(rows)
    end
  end
end