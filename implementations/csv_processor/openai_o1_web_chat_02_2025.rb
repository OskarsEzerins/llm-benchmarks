class CsvProcessor
  CHUNK_SIZE = 100

  def self.process(data, transformations)
    headers = data.first.split(',')
    filter_fn = transformations[:filter]
    select_cols = transformations[:select]
    aggregates = transformations[:aggregate] || {}
    filtered_rows = []

    data.drop(1).each_slice(CHUNK_SIZE) do |chunk|
      chunk.each do |line|
        row_values = line.split(',')
        row_hash = headers.zip(row_values).to_h
        if filter_fn.nil? || filter_fn.call(row_hash)
          row_hash.select! { |k,_| select_cols.include?(k) } if select_cols
          filtered_rows << row_hash
        end
      end
    end

    aggregations = aggregates.each_with_object({}) do |(name, func), obj|
      obj[name] = func.call(filtered_rows)
    end

    { filtered_data: filtered_rows, aggregations: aggregations }
  end
end
