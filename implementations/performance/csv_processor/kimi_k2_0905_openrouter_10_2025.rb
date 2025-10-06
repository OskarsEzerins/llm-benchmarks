class CsvProcessor
  def self.process(input_data, transformations, chunk_size = 1000)
    processor = new(input_data, transformations, chunk_size)
    processor.process
  end

  def initialize(input_data, transformations, chunk_size)
    @input_data = input_data
    @transformations = transformations
    @chunk_size = chunk_size
    @headers = @input_data.first.split(',').map(&:strip)
  end

  def process
    filtered_rows = []
    aggregate_rows = []
    enum = @input_data.drop(1).each_slice(@chunk_size)

    enum.each do |chunk|
      chunk.each do |line|
        row = parse_row(line)
        next if @transformations[:filter] && !@transformations[:filter].call(row)
        if @transformations[:select]
          selected = {}
          @transformations[:select].each { |k| selected[k.to_s] = row[k.to_s] }
          filtered_rows << selected
        end
        aggregate_rows << row
      end
    end

    result = {}

    if @transformations[:select]
      result[:filtered_data] = filtered_rows
    end

    if @transformations[:aggregate]
      aggregations = {}
      @transformations[:aggregate].each do |key, func|
        aggregations[key] = func.call(aggregate_rows)
      end
      result[:aggregations] = aggregations
    end

    result
  end

  private

  def parse_row(line)
    fields = line.split(',').map(&:strip)
    @headers.zip(fields).to_h
  end
end