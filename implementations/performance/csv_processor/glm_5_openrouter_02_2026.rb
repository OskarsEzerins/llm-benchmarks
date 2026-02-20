class CsvProcessor
  DEFAULT_CHUNK_SIZE = 1000

  def self.process(input_data, transformations)
    return { filtered_data: [], aggregations: {} } if input_data.nil? || input_data.empty?

    headers = parse_line(input_data.first)
    return { filtered_data: [], aggregations: {} } if headers.empty?

    filter_proc = transformations[:filter]
    select_cols = transformations[:select]
    aggregate_procs = transformations[:aggregate]

    filtered_data = []
    total_rows = input_data.size - 1

    # Process data in chunks
    (1..total_rows).each_slice(DEFAULT_CHUNK_SIZE) do |batch_indices|
      batch_indices.each do |idx|
        line = input_data[idx]
        next if line.nil? || line.strip.empty?

        values = parse_line(line)
        row = headers.zip(values).to_h

        # Apply filtering
        next if filter_proc && !filter_proc.call(row)

        # Apply column selection
        row = row.select { |k, _| select_cols.include?(k) } if select_cols && !select_cols.empty?

        filtered_data << row
      end
    end

    # Apply aggregations
    aggregations = {}
    if aggregate_procs
      aggregate_procs.each do |key, proc|
        aggregations[key] = proc.call(filtered_data)
      end
    end

    {
      filtered_data: filtered_data,
      aggregations: aggregations
    }
  end

  def self.parse_line(line)
    fields = []
    field = String.new
    in_quotes = false
    i = 0

    while i < line.length
      char = line[i]

      if in_quotes
        if char == '"'
          # Check for escaped quote
          if i + 1 < line.length && line[i + 1] == '"'
            field << '"'
            i += 1
          else
            in_quotes = false
          end
        else
          field << char
        end
      else
        if char == '"'
          in_quotes = true
        elsif char == ','
          fields << field
          field = String.new
        else
          field << char
        end
      end
      i += 1
    end
    fields << field
    fields
  end
end