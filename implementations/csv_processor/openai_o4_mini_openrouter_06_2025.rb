class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations = {})
    header = parse_line(data.first)
    filter_proc      = transformations[:filter]
    select_cols      = transformations[:select]
    aggregate_procs  = transformations[:aggregate] || {}
    filtered         = []
    agg_rows         = []

    data.drop(1).each_slice(CHUNK_SIZE) do |chunk|
      chunk.each do |line|
        values = parse_line(line)
        row    = header.zip(values).to_h
        next if filter_proc && !filter_proc.call(row)
        filtered << (select_cols ? select_cols.map { |c| [c, row[c]] }.to_h : row)
        agg_rows << row
      end
    end

    aggregations = aggregate_procs.each_with_object({}) do |(key, proc), memo|
      memo[key] = proc.call(agg_rows)
    end

    { filtered_data: filtered, aggregations: aggregations }
  end

  def self.parse_line(line)
    line.split(',', -1)
  end
  private_class_method :parse_line
end