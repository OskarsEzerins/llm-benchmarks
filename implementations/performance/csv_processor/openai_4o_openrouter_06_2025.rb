class CsvProcessor
  def self.process(data, transformations)
    headers = data.first.split(',')
    rows = data[1..].map { |line| line.split(',').each_with_index.to_h { |value, index| [headers[index], value] } }
    
    filtered_data = filter_data(rows, transformations[:filter])
    selected_data = select_columns(filtered_data, transformations[:select])
    aggregations = aggregate_data(filtered_data, transformations[:aggregate])
    
    { filtered_data: selected_data, aggregations: aggregations }
  end
  
  private
  
  def self.filter_data(rows, filter_proc)
    return rows unless filter_proc
    rows.select { |row| filter_proc.call(row) }
  end
  
  def self.select_columns(rows, columns)
    return rows unless columns
    rows.map { |row| row.select { |key, _| columns.include?(key) } }
  end

  def self.aggregate_data(rows, aggregate_procs)
    return {} unless aggregate_procs
    aggregate_procs.transform_values { |proc| proc.call(rows) }
  end
end