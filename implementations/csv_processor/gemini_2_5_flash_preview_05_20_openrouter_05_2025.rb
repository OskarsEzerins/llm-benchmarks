class CsvProcessor
  CHUNK_SIZE = 1000

  def self.process(data, transformations)
    header, *rows = data.map { |line| line.strip.split(',') }
    header_map = header.each_with_index.to_h

    filtered_results = []
    aggregation_cache = {}
    
    rows.each_slice(CHUNK_SIZE) do |chunk|
      chunk.each do |row_values|
        row_hash = {}
        header.each_with_index { |h, i| row_hash[h] = row_values[i] }

        if transformations[:filter]
          next unless transformations[:filter].call(row_hash)
        end

        filtered_row = {}
        if transformations[:select]
          transformations[:select].each do |key|
            filtered_row[key] = row_hash[key]
          end
        else
          filtered_row = row_hash
        end
        filtered_results << filtered_row
      end
    end

    if transformations[:aggregate]
      transformations[:aggregate].each do |agg_name, agg_proc|
        aggregation_cache[agg_name] = agg_proc.call(filtered_results)
      end
    end

    {
      filtered_data: filtered_results,
      aggregations: aggregation_cache
    }
  end
end