class CsvProcessor
  def self.process(input_data, transformations = {})
    new(input_data, transformations).process
  end

  def initialize(input_data, transformations)
    @input_data = input_data
    @transformations = {
      filter: transformations[:filter] || ->(_) { true },
      select: transformations[:select],
      aggregate: transformations[:aggregate] || {}
    }
    @headers = @input_data.first.split(',')
  end

  def process
    processed_rows = parse_rows
    {
      filtered_data: apply_select(processed_rows),
      aggregations: apply_aggregate(processed_rows)
    }
  end

  private

  def parse_rows
    @input_data[1..-1].map do |row|
      row_data = row.split(',')
      @headers.zip(row_data).to_h
    end.select { |row| @transformations[:filter].call(row) }
  end

  def apply_select(rows)
    return rows unless @transformations[:select]

    rows.map do |row|
      @transformations[:select].map { |key| [key, row[key]] }.to_h
    end
  end

  def apply_aggregate(rows)
    @transformations[:aggregate].transform_values do |aggregator|
      aggregator.call(rows)
    end
  end
end