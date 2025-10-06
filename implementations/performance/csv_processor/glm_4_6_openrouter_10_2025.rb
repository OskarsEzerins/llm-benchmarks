class CsvProcessor
  def self.process(input_data, transformations)
    headers = input_data.first.split(',')
    data_rows = input_data[1..-1]

    filtered_rows = filter_rows(data_rows, headers, transformations[:filter])
    selected_rows = select_columns(filtered_rows, headers, transformations[:select])
    aggregations = calculate_aggregations(data_rows, headers, transformations[:aggregate])

    {
      filtered_data: selected_rows,
      aggregations: aggregations
    }
  end

  private

  def self.filter_rows(rows, headers, filter_proc)
    return rows unless filter_proc

    rows.each_slice(1000).flat_map do |chunk|
      chunk.select do |row|
        values = row.split(',')
        row_hash = headers.zip(values).to_h
        filter_proc.call(row_hash)
      end
    end
  end

  def self.select_columns(rows, headers, selected_columns)
    return rows.map { |row| headers.zip(row.split(',')).to_h } unless selected_columns

    rows.map do |row|
      values = row.split(',')
      row_hash = headers.zip(values).to_h
      row_hash.slice(*selected_columns)
    end
  end

  def self.calculate_aggregations(rows, headers, aggregate_procs)
    return {} unless aggregate_procs

    rows.each_slice(1000).reduce({}) do |acc, chunk|
      chunk_rows = chunk.map { |row| headers.zip(row.split(',')).to_h }
      aggregate_procs.each do |key, proc|
        acc[key] = proc.call(chunk_rows) if acc[key].nil?
      end
      acc
    end
  end
end