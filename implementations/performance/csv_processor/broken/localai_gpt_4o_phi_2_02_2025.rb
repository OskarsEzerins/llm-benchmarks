require 'csv'

class CsvProcessor
  def self.process(input_data, transformations)
    data = csv_data(input_data)

    filtered_data = filter_data(data, transformations[:filter])
    selected_data = select_data(filtered_data, transformations[:select])
    aggregations = aggregate_data(selected_data, transformations[:aggregate])

    { filtered_data: filtered_data, aggregations: aggregations }
  end

  def self.csv_data(input_data)
    CSV.new(input_data, headers: true).map(&:to_h)
  end

  def self.filter_data(data, filter)
    data.select { |row| filter.call(row) }
  end

  def self.select_data(data, columns)
    data.map { |row| columns.reduce({}|{(k,v), row[k]=v}) }.map(&:to_h)
  end

  def self.aggregate_data(data, aggregations)
    aggregations.reduce({}) do |result, (name, transformation)|
      result[name] = transformation.call(data.map(&:to_h))
      result
    end
  end
end
