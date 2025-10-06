class CsvProcessor
  DEFAULT_CHUNK_SIZE = 500

  def self.process(data_lines, transformations = {}, chunk_size: DEFAULT_CHUNK_SIZE)
    data_lines = Array(data_lines)
    return { filtered_data: [], aggregations: {} } if data_lines.empty?

    header = parse_line(data_lines.first.to_s.chomp)
    filter_fn = transformations[:filter]
    select_columns = transformations[:select]
    aggregate_config = transformations[:aggregate] || {}

    filtered_rows = []
    filtered_output = []

    data_lines.drop(1).each_slice(chunk_size) do |chunk|
      chunk.each do |line|
        next if line.nil? || line.strip.empty?

        row_values = parse_line(line.chomp)
        row_hash = map_row(header, row_values)

        next if filter_fn && !filter_fn.call(row_hash)

        filtered_rows << row_hash
        filtered_output << project_row(row_hash, select_columns)
      end
    end

    aggregations = compute_aggregations(filtered_rows, aggregate_config)
    { filtered_data: filtered_output, aggregations: aggregations }
  end

  class << self
    private

    def parse_line(line)
      fields = []
      current = +""
      in_quotes = false
      i = 0
      while i < line.length
        char = line[i]
        if char == '"'
          if in_quotes && line[i + 1] == '"'
            current << '"'
            i += 1
          else
            in_quotes = !in_quotes
          end
        elsif char == ',' && !in_quotes
          fields << current
          current = +""
        else
          current << char
        end
        i += 1
      end
      fields << current
      fields
    end

    def map_row(header, values)
      row = {}
      header.each_with_index do |key, index|
        row[key] = values[index] || ""
      end
      row
    end

    def project_row(row, select_columns)
      return row.dup if select_columns.nil? || select_columns.empty?
      select_columns.each_with_object({}) do |column, projected|
        projected[column] = row[column]
      end
    end

    def compute_aggregations(rows, config)
      return {} if config.nil? || config.empty?
      config.each_with_object({}) do |(name, handler), result|
        next unless handler.respond_to?(:call)
        result[name] = handler.call(rows)
      end
    end
  end
end