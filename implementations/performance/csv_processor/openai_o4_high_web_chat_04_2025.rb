class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations = {})
    header = data.first.split(',')
    filter_fn = transformations[:filter]
    select_fields = transformations[:select]
    aggregate_fns = transformations[:aggregate] || {}

    filtered_rows = []

    data.drop(1).each_slice(CHUNK_SIZE) do |chunk|
      chunk.each do |line|
        row = header.zip(line.split(',')).to_h
        next if filter_fn && !filter_fn.call(row)
        filtered_rows << row
      end
    end

    selected_data = if select_fields
      filtered_rows.map { |row| row.select { |k, _| select_fields.include?(k) } }
    else
      filtered_rows
    end

    aggregations = aggregate_fns.each_with_object({}) do |(key, fn), result|
      result[key] = fn.call(filtered_rows)
    end

    { filtered_data: selected_data, aggregations: aggregations }
  end
end
