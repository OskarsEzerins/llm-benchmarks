class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(input_data, transformations = {})
    new.process(input_data, transformations)
  end

  def process(input_data, transformations)
    header = input_data.first
    field_names = parse_header(header)
    rows = LazyRowEnumerator.new(input_data.drop(1), field_names)

    filtered_rows = if transformations[:filter]
                      rows.lazy.select { |row| transformations[:filter].call(row) }
                    else
                      rows.lazy
                    end

    selected_rows = if transformations[:select]
                      filtered_rows.map do |row|
                        transformations[:select].each_with_object({}) do |field, selected|
                          selected[field] = row[field]
                        end
                      end
                    else
                      filtered_rows
                    end

    result_rows = selected_rows.to_a

    aggregations = {}
    if transformations[:aggregate]
      transformations[:aggregate].each do |key, func|
        aggregations[key] = func.call(result_rows)
      end
    end

    {
      filtered_data: result_rows,
      aggregations: aggregations
    }
  end

  private

  def parse_header(header_line)
    header_line.split(',').map(&:strip)
  end

  class LazyRowEnumerator
    include Enumerable

    def initialize(data_lines, field_names)
      @data_lines = data_lines
      @field_names = field_names
    end

    def each
      return enum_for(:each) unless block_given?

      @data_lines.each do |line|
        values = line.split(',').map(&:strip)
        row = {}
        @field_names.each_with_index do |field, i|
          row[field] = values[i] || ''
        end
        yield row
      end
    end
  end
end