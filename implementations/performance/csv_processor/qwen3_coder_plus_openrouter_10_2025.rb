class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations = {})
    new.process(data, transformations)
  end

  def process(data, transformations = {})
    headers = parse_headers(data.first)
    filter_proc = transformations[:filter]
    select_fields = transformations[:select]
    aggregations = transformations[:aggregate] || {}

    filtered_data = []
    all_rows = []

    process_in_chunks(data) do |chunk|
      chunk.each_with_index do |row_str, index|
        next if index == 0 && chunk == data # Skip header row
        
        row_hash = parse_row(row_str, headers)
        all_rows << row_hash
        
        if !filter_proc || filter_proc.call(row_hash)
          filtered_row = select_fields ? row_hash.slice(*select_fields) : row_hash
          filtered_data << filtered_row
        end
      end
    end

    result = { filtered_data: filtered_data }
    
    if aggregations.any?
      result[:aggregations] = {}
      aggregations.each do |name, agg_proc|
        result[:aggregations][name] = agg_proc.call(all_rows)
      end
    end

    result
  end

  private

  def parse_headers(header_line)
    header_line.strip.split(',')
  end

  def parse_row(row_line, headers)
    values = row_line.strip.split(',')
    headers.each_with_object({}).with_index do |(header, hash), index|
      hash[header] = values[index] || ""
    end
  end

  def process_in_chunks(data)
    data.each_slice(CHUNK_SIZE) do |chunk|
      yield chunk
    end
  end
end