class CsvProcessor
  def self.process(data, transformations)
    raise ArgumentError, 'Data must be an array' unless data.is_a?(Array)

    headers = parse_headers(data.first)
    filtered_data = []
    data[1..].each_slice(100) do |chunk|
      filtered_data.concat(process_chunk(chunk, headers, transformations))
    end

    selected_data = apply_select(filtered_data, transformations[:select])
    aggregations = perform_aggregations(selected_data, transformations[:aggregate])

    {
      filtered_data: selected_data,
      aggregations: aggregations,
    }
  end

  def self.parse_headers(header_row)
    header_row.chomp.split(',')
  end

  def self.process_chunk(chunk, headers, transformations)
    chunk.map do |row|
      row_values = row.chomp.split(',')
      row_hash = {}
      headers.each_with_index do |header, index|
        row_hash[header] = row_values[index]
      end

      apply_filter(row_hash, transformations[:filter]) ? row_hash : nil
    end.compact
  end

  def self.apply_filter(row, filter)
    filter.nil? || filter.call(row)
  end

  def self.apply_select(data, select_columns)
    return data if select_columns.nil?

    data.map do |row|
      selected_row = {}
      select_columns.each do |column|
        selected_row[column] = row[column]
      end
      selected_row
    end
  end

  def self.perform_aggregations(data, aggregations)
    return {} if aggregations.nil?

    result = {}
    aggregations.each do |name, func|
      result[name] = func.call(data)
    end
    result
  end
end
