class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations)
    headers = data[0].split(",").map(&:strip)
    filter_fn = transformations[:filter]
    select_fields = transformations[:select]
    aggregate_fns = transformations[:aggregate] || {}

    filtered_data = []
    filtered_rows_for_agg = []

    data_enum = Enumerator.new do |yielder|
      data[1..-1].each_slice(CHUNK_SIZE) do |chunk|
        chunk.each do |line|
          values = parse_csv_line(line)
          row = headers.zip(values).to_h
          yielder << row
        end
      end
    end

    data_enum.each do |row|
      if filter_fn.nil? || filter_fn.call(row)
        filtered_rows_for_agg << row
        if select_fields
          filtered_data << select_fields.map { |key| [key, row[key]] }.to_h
        else
          filtered_data << row.dup
        end
      end
    end

    aggregations = {}
    aggregate_fns.each do |name, fn|
      aggregations[name] = fn.call(filtered_rows_for_agg)
    end

    {
      filtered_data: filtered_data,
      aggregations: aggregations
    }
  end

  def self.parse_csv_line(line)
    result = []
    field = ''
    in_quotes = false
    i = 0
    while i < line.length
      char = line[i]
      if in_quotes
        if char == '"'
          if line[i+1] == '"'
            field << '"'
            i += 1
          else
            in_quotes = false
          end
        else
          field << char
        end
      else
        case char
        when '"'
          in_quotes = true
        when ','
          result << field
          field = ''
        else
          field << char
        end
      end
      i += 1
    end
    result << field
    result
  end
end