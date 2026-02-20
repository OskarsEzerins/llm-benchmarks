class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(input_data, transformations)
    filtered_data = []
    aggregation_buffer = []

    process_in_chunks(input_data) do |chunk|
      parsed_chunk = parse_csv(chunk)
      
      if transformations[:filter]
        parsed_chunk.select! { |row| transformations[:filter].call(row) }
      end
      
      filtered_data.concat(parsed_chunk)
      aggregation_buffer.concat(parsed_chunk)
    end

    if transformations[:select]
      selected_columns = transformations[:select]
      filtered_data = filtered_data.map do |row|
        row.select { |key, _| selected_columns.include?(key) }
      end
    end

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |name, agg_lambda|
        aggregations[name] = agg_lambda.call(aggregation_buffer)
      end
    end

    {
      filtered_data: filtered_data,
      aggregations: aggregations
    }
  end

  def self.process_in_chunks(data, &block)
    data.each_slice(CHUNK_SIZE, &block)
  end

  def self.parse_csv(data)
    return [] if data.empty?

    lines = data.join("\n").split("\n").reject(&:empty?)
    return [] if lines.length < 2

    headers = parse_csv_line(lines.first)

    lines[1..-1].each_with_object([]) do |line, result|
      values = parse_csv_line(line)
      next if values.length != headers.length

      row = headers.zip(values).to_h
      result << row
    end
  end

  def self.parse_csv_line(line)
    values = []
    current = ""
    in_quotes = false

    line.each_char do |char|
      case char
      when '"'
        in_quotes = !in_quotes
      when ','
        unless in_quotes
          values << current.strip
          current = ""
        else
          current << char
        end
      else
        current << char
      end
    end
    values << current.strip
    values
  end
end