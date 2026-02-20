require 'csv'

class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations)
    new(data, transformations).process
  end

  def initialize(data, transformations)
    @data = data
    @transformations = transformations
    @headers = parse_headers
  end

  def process
    filtered_data = []
    aggregation_data = []

    process_chunks do |row|
      row_hash = array_to_hash(row)
      
      if passes_filter?(row_hash)
        filtered_data << apply_select(row_hash)
        aggregation_data << row_hash
      end
    end

    {
      filtered_data: filtered_data,
      aggregations: compute_aggregations(aggregation_data)
    }
  end

  private

  def parse_headers
    return [] if @data.empty?
    CSV.parse_line(@data.first)
  end

  def process_chunks
    data_rows = @data.drop(1)
    return if data_rows.empty?

    data_rows.each_slice(CHUNK_SIZE) do |slice|
      csv_content = slice.join("\n")
      CSV.parse(csv_content, headers: false).each do |parsed_row|
        yield parsed_row
      end
    end
  end

  def array_to_hash(row)
    @headers.zip(row).to_h
  end

  def passes_filter?(row)
    filter_proc = @transformations[:filter]
    filter_proc ? filter_proc.call(row) : true
  end

  def apply_select(row)
    select_cols = @transformations[:select]
    select_cols ? row.slice(*select_cols) : row
  end

  def compute_aggregations(rows)
    agg_procs = @transformations[:aggregate]
    return {} unless agg_procs

    agg_procs.transform_values { |proc| proc.call(rows) }
  end
end