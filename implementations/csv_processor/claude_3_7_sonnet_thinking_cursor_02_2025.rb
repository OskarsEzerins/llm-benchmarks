class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(input_data, transformations)
    result = {
      filtered_data: [],
      aggregations: {}
    }

    return result if input_data.empty?

    headers = parse_headers(input_data[0])

    # Process in chunks
    rows = []
    chunk = []

    input_data[1..-1].each_with_index do |line, index|
      chunk << line_to_hash(line, headers)

      if chunk.size >= CHUNK_SIZE || index == input_data.length - 2
        process_chunk(chunk, transformations, rows)
        chunk = []
      end
    end

    # Process any remaining data
    process_chunk(chunk, transformations, rows) unless chunk.empty?

    # Apply filter if provided
    filtered_rows = transformations[:filter] ? rows.select(&transformations[:filter]) : rows

    # Apply select if provided
    if transformations[:select]
      result[:filtered_data] = filtered_rows.map do |row|
        transformations[:select].each_with_object({}) do |field, selected_row|
          selected_row[field] = row[field] if row.key?(field)
        end
      end
    else
      result[:filtered_data] = filtered_rows
    end

    # Apply aggregations if provided
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, aggregation_func|
        result[:aggregations][key] = aggregation_func.call(rows)
      end
    end

    result
  end

  private

  def self.parse_headers(header_line)
    header_line.strip.split(',')
  end

  def self.line_to_hash(line, headers)
    values = line.strip.split(',')
    headers.zip(values).to_h
  end

  def self.process_chunk(chunk, transformations, rows)
    rows.concat(chunk)
  end
end
