class CsvProcessor
  def self.process(data, transformations)
    headers = nil
    filtered_rows = []
    sum_age = 0.0
    count_age = 0

    # Helper to parse a CSV line into hash
    parse_line = lambda do |line|
      values = line.strip.split(",")
      hash = {}
      headers.each_with_index do |header, idx|
        hash[header] = values[idx]
      end
      hash
    end

    # Process header line
    data_enum = data.each
    headers = data_enum.next.strip.split(",")
    select_fields = transformations[:select]
    filter_proc = transformations[:filter]
    aggregate_proc = transformations[:aggregate]

    # First pass: filter and collect for aggregation
    data_enum.each do |line|
      row = parse_line.call(line)
      # Apply filter if defined
      if filter_proc.nil? || filter_proc.call(row)
        # For aggregation
        if aggregate_proc && aggregate_proc[:avg_age]
          age = row["age"].to_i
          sum_age += age
          count_age += 1
        end
        filtered_rows << row
      end
    end

    # Prepare filtered data with only selected fields
    result_rows = filtered_rows.map do |row|
      if select_fields
        result = {}
        select_fields.each { |field| result[field] = row[field] }
        result
      else
        row
      end
    end

    # Compute aggregations
    aggregations = {}
    if aggregate_proc && aggregate_proc[:avg_age]
      avg_age = count_age.zero? ? 0 : sum_age / count_age
      aggregations[:avg_age] = avg_age
    end

    {
      filtered_data: result_rows,
      aggregations: aggregations
    }
  end
end
