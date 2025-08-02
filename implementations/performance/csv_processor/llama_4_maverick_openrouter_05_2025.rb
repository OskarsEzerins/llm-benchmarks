class CsvProcessor
  def self.process(data, transformations)
    new(data, transformations).process
  end

  def initialize(data, transformations)
    @data = data
    @transformations = transformations
    @headers = nil
    @filtered_data = []
    @aggregations = {}
  end

  def process
    chunk_size = 100
    @data.each_slice(chunk_size) do |chunk|
      process_chunk(chunk)
    end
    finalize_aggregations
    { filtered_data: @filtered_data, aggregations: @aggregations }
  end

  private

  def process_chunk(chunk)
    chunk.each_with_index do |row, index|
      if index == 0 && @headers.nil?
        @headers = row.split(",")
        next
      end
      process_row(row.split(","))
    end
  end

  def process_row(row)
    row_hash = @headers.zip(row).to_h
    return unless apply_filter(row_hash)

    @filtered_data << select_columns(row_hash) if @transformations[:select]
    apply_aggregations(row_hash) if @transformations[:aggregate]
  end

  def apply_filter(row)
    return true unless @transformations[:filter]

    @transformations[:filter].call(row)
  end

  def select_columns(row)
    @transformations[:select].map { |col| [col, row[col]] }.to_h
  end

  def apply_aggregations(row)
    @transformations[:aggregate].each do |key, aggregation|
      @aggregations[key] ||= []
      @aggregations[key] << aggregation.call([row])
    end
  end

  def finalize_aggregations
    return unless @transformations[:aggregate]

    @transformations[:aggregate].each_key do |key|
      @aggregations[key] = @aggregations[key].flatten[0]
    end
  end
end