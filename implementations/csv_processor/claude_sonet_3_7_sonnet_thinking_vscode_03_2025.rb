class CsvProcessor
  def self.process(input_data, transformations, chunk_size = 1000)
    headers = parse_headers(input_data[0])
    filtered_data = []
    rows_for_aggregation = transformations[:aggregate] ? [] : nil

    input_data[1..].each_slice(chunk_size) do |chunk|
      rows = chunk.map { |row_str| parse_row(row_str, headers) }

      filtered_rows = if transformations[:filter]
        rows.select { |row| transformations[:filter].call(row) }
      else
        rows
      end

      rows_for_aggregation&.concat(filtered_rows)

      selected_rows = if transformations[:select]
        filtered_rows.map { |row| select_fields(row, transformations[:select]) }
      else
        filtered_rows
      end

      filtered_data.concat(selected_rows)
    end

    aggregations = if rows_for_aggregation
      apply_aggregations(rows_for_aggregation, transformations[:aggregate])
    else
      {}
    end

    { filtered_data:, aggregations: }
  end

  private

  def self.parse_headers(header_row)
    header_row.split(',').map(&:strip)
  end

  def self.parse_row(row_str, headers)
    values = row_str.split(',').map(&:strip)
    headers.zip(values).to_h
  end

  def self.select_fields(row, fields)
    fields.each_with_object({}) do |field, result|
      result[field] = row[field] if row.key?(field)
    end
  end

  def self.apply_aggregations(rows, aggregations)
    return {} unless aggregations

    aggregations.each_with_object({}) do |(name, agg_function), result|
      result[name] = agg_function.call(rows)
    end
  end
end
