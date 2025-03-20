# frozen_string_literal: true

class CsvProcessor
  DEFAULT_CHUNK_SIZE = 1000

  def self.process(data, transformations, chunk_size = DEFAULT_CHUNK_SIZE)
    new(data, transformations, chunk_size).process
  end

  def initialize(data, transformations, chunk_size)
    @data = data
    @transformations = transformations
    @chunk_size = chunk_size
    @headers = []
    @result = { filtered_data: [], aggregations: {} }
    @processed_rows = []
  end

  def process
    return @result if @data.empty?

    parse_headers
    process_in_chunks
    apply_aggregations if @transformations[:aggregate]

    @result
  end

  private

  def parse_headers
    @headers = @data[0].split(",").map(&:strip)
  end

  def process_in_chunks
    chunk = []

    @data[1..].each do |line|
      chunk << parse_row(line)

      if chunk.size >= @chunk_size
        process_chunk(chunk)
        chunk = []
      end
    end

    process_chunk(chunk) unless chunk.empty?
  end

  def parse_row(line)
    values = line.split(",").map(&:strip)
    @headers.zip(values).to_h
  end

  def process_chunk(chunk)
    chunk.each do |row|
      process_row(row)
    end
  end

  def process_row(row)
    return unless passes_filter?(row)

    @processed_rows << row

    if @transformations[:select]
      selected_row = select_fields(row)
      @result[:filtered_data] << selected_row
    else
      @result[:filtered_data] << row.dup
    end
  end

  def passes_filter?(row)
    return true unless @transformations[:filter]

    @transformations[:filter].call(row)
  end

  def select_fields(row)
    @transformations[:select].each_with_object({}) do |field, selected|
      selected[field] = row[field] if row.key?(field)
    end
  end

  def apply_aggregations
    @transformations[:aggregate].each do |name, aggregation_proc|
      @result[:aggregations][name] = aggregation_proc.call(@processed_rows)
    end
  end
end
