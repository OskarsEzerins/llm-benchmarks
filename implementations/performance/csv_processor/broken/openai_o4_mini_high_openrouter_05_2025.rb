require 'csv'

class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations)
    return { filtered_data: [], aggregations: {} } if data.empty?
    header       = CSV.parse_line(data.first)
    filter_fn    = transformations[:filter]
    select_cols  = transformations[:select]
    aggregate_fns = transformations[:aggregate] || {}
    filtered_rows = []

    data.drop(1).each_slice(CHUNK_SIZE) do |slice|
      slice.each do |line|
        fields = CSV.parse_line(line)
        row    = header.zip(fields).to_h
        if filter_fn.nil? || filter_fn.call(row)
          filtered_rows << row
        end
      end
    end

    aggregations = aggregate_fns.each_with_object({}) do |(key, fn), memo|
      memo[key] = fn.call(filtered_rows)
    end

    result_rows = if select_cols
      filtered_rows.map { |row| row.select { |k, _| select_cols.include?(k) } }
    else
      filtered_rows
    end

    { filtered_data: result_rows, aggregations: aggregations }
  end
end