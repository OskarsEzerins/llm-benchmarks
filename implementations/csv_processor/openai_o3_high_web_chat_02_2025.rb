class CsvProcessor
  CHUNK_SIZE = 100

  def self.process(input_data, transformations = {})
    header_line = input_data.first
    headers = parse_csv_line(header_line)
    filtered_rows_full = []
    filtered_data = []

    filter_proc = transformations[:filter]
    select_columns = transformations[:select]
    aggregate_transformations = transformations[:aggregate] || {}

    input_data[1..-1].each_slice(CHUNK_SIZE) do |chunk|
      chunk.each do |line|
        row_values = parse_csv_line(line)
        row_hash = headers.zip(row_values).to_h

        next if filter_proc && !filter_proc.call(row_hash)

        filtered_rows_full << row_hash

        if select_columns
          selected_row = {}
          select_columns.each { |col| selected_row[col] = row_hash[col] }
          filtered_data << selected_row
        else
          filtered_data << row_hash
        end
      end
    end

    aggregations = {}
    aggregate_transformations.each { |name, agg_proc| aggregations[name] = agg_proc.call(filtered_rows_full) }

    { filtered_data: filtered_data, aggregations: aggregations }
  end

  def self.parse_csv_line(line)
    line.strip.split(',')
  end

  private_class_method :parse_csv_line
end
