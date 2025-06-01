class CsvProcessor
  def self.process(data, transformations, chunk_size: 1000)
    return { filtered_data: [], aggregations: {} } if data.empty?

    headers = parse_line(data[0])
    filter_fn = transformations[:filter] || ->(_row) { true }
    select_cols = transformations[:select]
    aggregate_fns = transformations[:aggregate] || {}

    filtered_data = []
    aggregation_rows = []

    # Helper to build row hash from array
    build_row = ->(line) do
      values = parse_line(line)
      row = {}
      headers.each_with_index { |h, i| row[h] = values[i] }
      row
    end

    # Process data in chunks (skip header line)
    i = 1
    while i < data.size
      chunk_end = [i + chunk_size - 1, data.size - 1].min
      chunk = data[i..chunk_end]

      chunk.each do |line|
        row = build_row.call(line)
        if filter_fn.call(row)
          filtered_data << (select_cols ? row.select { |k, _| select_cols.include?(k) } : row)
          aggregation_rows << row
        end
      end

      i = chunk_end + 1
    end

    aggregations = {}
    aggregate_fns.each do |key, agg_fn|
      aggregations[key] = agg_fn.call(aggregation_rows)
    end

    { filtered_data: filtered_data, aggregations: aggregations }
  end

  def self.parse_line(line)
    # Basic CSV parser (handles simple cases without quotes/commas inside fields)
    line.split(",")
  end
end