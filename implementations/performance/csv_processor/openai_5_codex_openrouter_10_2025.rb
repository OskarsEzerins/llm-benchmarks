require "csv"

class CsvProcessor
  DEFAULT_CHUNK_SIZE = 1_000

  def self.process(data_lines, transformations = {}, chunk_size: DEFAULT_CHUNK_SIZE)
    raise ArgumentError, "data_lines must be a non-empty Array" unless data_lines.is_a?(Array) && !data_lines.empty?

    chunk_size = chunk_size.to_i
    raise ArgumentError, "chunk_size must be positive" if chunk_size <= 0

    header = parse_line(data_lines.first)
    raise ArgumentError, "CSV header missing" if header.nil? || header.empty?

    filter_proc = transformations[:filter]
    select_fields = Array(transformations[:select]).compact
    aggregates = transformations.fetch(:aggregate, {})

    validate_transformations!(filter_proc, select_fields, aggregates, header)

    filtered_rows = process_rows(data_lines.drop(1), header, filter_proc, chunk_size)
    aggregation_results = compute_aggregates(filtered_rows, aggregates)
    selected_data = apply_selection(filtered_rows, select_fields)

    {
      filtered_data: selected_data,
      aggregations: aggregation_results
    }
  end

  class << self
    private

    def parse_line(line)
      CSV.parse_line(line.to_s, headers: false) || []
    rescue CSV::MalformedCSVError => e
      raise ArgumentError, "Invalid CSV line: #{e.message}"
    end

    def validate_transformations!(filter_proc, select_fields, aggregates, header)
      if filter_proc && !filter_proc.respond_to?(:call)
        raise ArgumentError, "filter must respond to #call"
      end

      unless select_fields.empty?
        unknown = select_fields - header
        raise ArgumentError, "Unknown columns in select: #{unknown.join(', ')}" unless unknown.empty?
      end

      aggregates.each do |name, fn|
        raise ArgumentError, "Aggregate #{name} must respond to #call" unless fn.respond_to?(:call)
      end
    end

    def process_rows(data_lines, header, filter_proc, chunk_size)
      filtered = []
      data_lines.each_slice(chunk_size) do |chunk|
        chunk.each do |line|
          next if line.nil? || line.strip.empty?
          values = parse_line(line)
          row = build_row(header, values)
          next if filter_proc && !filter_proc.call(row)
          filtered << row
        end
      end
      filtered
    end

    def build_row(header, values)
      row = {}
      header.each_with_index do |column, index|
        row[column] = values[index]
      end
      row
    end

    def compute_aggregates(filtered_rows, aggregates)
      return {} if aggregates.nil? || aggregates.empty?
      aggregates.each_with_object({}) do |(name, fn), result|
        result[name] = fn.call(filtered_rows)
      end
    end

    def apply_selection(filtered_rows, select_fields)
      return filtered_rows.map(&:dup) if select_fields.empty?
      filtered_rows.map do |row|
        select_fields.each_with_object({}) do |field, selected|
          selected[field] = row[field]
        end
      end
    end
  end
end