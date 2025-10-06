class CsvProcessor
  def self.process(data, transformations)
    return { filtered_data: [], aggregations: {} } if data.empty?

    headers = data[0].split(',').map(&:strip)
    filter_proc = transformations[:filter] || ->(row) { true }
    select_cols = transformations[:select] || headers
    agg_configs = transformations[:aggregate] || {}

    filtered_rows = []
    data[1..-1].each do |line|
      values = line.split(',').map(&:strip)
      row = Hash[headers.zip(values)]
      filtered_rows << row if filter_proc.call(row)
    end

    selected_data = filtered_rows.map do |row|
      row.select { |key, _| select_cols.include?(key) }
    end

    aggregations = {}
    agg_configs.each do |key, proc|
      aggregations[key] = proc.call(filtered_rows)
    end

    {
      filtered_data: selected_data,
      aggregations: aggregations
    }
  end
end