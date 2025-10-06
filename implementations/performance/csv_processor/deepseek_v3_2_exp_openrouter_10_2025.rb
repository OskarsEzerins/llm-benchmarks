class CsvProcessor
  def self.process(input_data, transformations)
    new(input_data, transformations).process
  end

  def initialize(input_data, transformations)
    @input_data = input_data
    @transformations = transformations
    @headers = []
    @filtered_rows = []
    @aggregation_rows = []
  end

  def process
    parse_csv
    apply_transformations
    build_result
  end

  private

  def parse_csv
    @headers = @input_data.first.split(",").map(&:strip)
    
    @input_data[1..-1].each do |row|
      values = row.split(",").map(&:strip)
      parsed_row = @headers.zip(values).to_h
      @aggregation_rows << parsed_row if @transformations[:aggregate]
    end
  end

  def apply_transformations
    return unless @transformations[:filter] || @transformations[:select]

    @aggregation_rows.each do |row|
      next if @transformations[:filter] && !@transformations[:filter].call(row)
      
      if @transformations[:select]
        selected_row = row.select { |k, _| @transformations[:select].include?(k) }
        @filtered_rows << selected_row
      else
        @filtered_rows << row
      end
    end
  end

  def build_result
    result = {}
    result[:filtered_data] = @filtered_rows if @transformations[:select] || @transformations[:filter]
    
    if @transformations[:aggregate]
      result[:aggregations] = {}
      @transformations[:aggregate].each do |key, agg_func|
        result[:aggregations][key] = agg_func.call(@aggregation_rows)
      end
    end
    
    result
  end
end