class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations = {})
    headers = nil
    filtered = []
    all_rows_for_agg = []

    data_enum = data.each

    loop do
      chunk = []
      begin
        CHUNK_SIZE.times do
          line = data_enum.next
          if headers.nil?
            headers = parse_csv_line(line)
          else
            chunk << parse_row(line, headers)
          end
        end
      rescue StopIteration
        # process what's left
      end

      break if chunk.empty? && headers

      chunk.each do |row|
        if !transformations[:filter] || transformations[:filter].call(row)
          filtered << select_columns(row, transformations[:select])
        end
        all_rows_for_agg << row if transformations[:aggregate]
      end

      # Memory efficiency: yield filtered/agg if very large or implement streaming here if needed
    end

    result = {}
    result[:filtered_data] = filtered

    if transformations[:aggregate]
      aggs = {}
      transformations[:aggregate].each do |agg_name, agg_fn|
        aggs[agg_name] = agg_fn.call(
          all_rows_for_agg.select { |row|
            !transformations[:filter] || transformations[:filter].call(row)
          }
        )
      end
      result[:aggregations] = aggs
    end

    result
  end

  def self.parse_csv_line(line)
    line.chomp.split(",", -1)
  end

  def self.parse_row(line, headers)
    values = parse_csv_line(line)
    Hash[headers.zip(values)]
  end

  def self.select_columns(row, columns)
    return row unless columns
    columns.each_with_object({}) { |col, h| h[col] = row[col] }
  end
end
