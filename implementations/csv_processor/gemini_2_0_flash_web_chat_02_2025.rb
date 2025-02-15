class CsvProcessor
  def self.process(data, transformations)
    header = data[0].split(",")
    rows = data[1..-1].map { |row| Hash[header.zip(row.split(","))] }

    filtered_data = apply_filter(rows, transformations[:filter])
    selected_data = apply_select(filtered_data, transformations[:select])
    aggregations = apply_aggregations(filtered_data, transformations[:aggregate])

    {
      filtered_data: selected_data,
      aggregations: aggregations
    }
  end

  private

  def self.apply_filter(rows, filter_proc)
    return rows unless filter_proc

    rows.select { |row| filter_proc.call(row) }
  end

  def self.apply_select(rows, select_columns)
    return rows unless select_columns

    rows.map do |row|
      selected_row = {}
      select_columns.each do |col|
        selected_row[col] = row[col] if row.key?(col)
      end
      selected_row
    end
  end

  def self.apply_aggregations(rows, aggregate_procs)
    return {} unless aggregate_procs

    aggregations = {}
    aggregate_procs.each do |name, agg_proc|
      aggregations[name] = agg_proc.call(rows)
    end
    aggregations
  end


  def self.chunk_process(data, transformations, chunk_size: 1000) # Added chunking
    header = data[0].split(",")
    results = { filtered_data: [], aggregations: {} }

    data[1..-1].each_slice(chunk_size) do |chunk|
        rows = chunk.map { |row| Hash[header.zip(row.split(","))] }

        filtered_chunk = apply_filter(rows, transformations[:filter])
        selected_chunk = apply_select(filtered_chunk, transformations[:select])

        results[:filtered_data].concat(selected_chunk)

        if transformations[:aggregate]
          transformations[:aggregate].each do |name, agg_proc|
              results[:aggregations][name] ||= [] # Initialize if needed
              results[:aggregations][name].concat(filtered_chunk) # Collect rows for aggregation
          end
        end
    end

    # Perform aggregations after processing all chunks
    if transformations[:aggregate]
        transformations[:aggregate].each do |name, agg_proc|
            results[:aggregations][name] = agg_proc.call(results[:aggregations][name])
        end
    end

    results
  end
end
