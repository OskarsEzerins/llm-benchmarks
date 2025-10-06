class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations = {})
    new(data, transformations).process
  end

  def initialize(data, transformations)
    @data = data
    @transformations = transformations
    @headers = nil
  end

  def process
    results = { filtered_data: [], aggregations: {} }
    rows_for_aggregation = []

    process_in_chunks do |chunk|
      chunk.each do |row_hash|
        if apply_filter(row_hash)
          selected_row = apply_select(row_hash)
          results[:filtered_data] << selected_row
          rows_for_aggregation << row_hash if @transformations[:aggregate]
        end
      end
    end

    if @transformations[:aggregate]
      results[:aggregations] = apply_aggregations(rows_for_aggregation)
    end

    results
  end

  private

  def process_in_chunks(&block)
    return enum_for(:process_in_chunks) unless block_given?

    @headers = parse_headers(@data.first)
    row_count = @data.length - 1
    offset = 1

    while offset <= row_count
      chunk = @data[offset, CHUNK_SIZE]
      break unless chunk

      chunk_rows = chunk.map { |line| parse_row(line) }
      block.call(chunk_rows)
      offset += CHUNK_SIZE
    end
  end

  def parse_headers(header_line)
    header_line.split(',').map(&:strip)
  end

  def parse_row(line)
    values = line.split(',').map(&:strip)
    Hash[@headers.zip(values)]
  end

  def apply_filter(row)
    filter_proc = @transformations[:filter]
    return true unless filter_proc
    filter_proc.call(row)
  end

  def apply_select(row)
    select_fields = @transformations[:select]
    return row unless select_fields
    row.select { |key, _| select_fields.include?(key) }
  end

  def apply_aggregations(rows)
    aggregations = {}
    aggregate_defs = @transformations[:aggregate] || {}
    aggregate_defs.each do |name, proc|
      aggregations[name] = proc.call(rows)
    end
    aggregations
  end
end