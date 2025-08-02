class CsvProcessor
  DEFAULT_CHUNK_SIZE = 1000

  def self.process(input_data, transformations, chunk_size: DEFAULT_CHUNK_SIZE)
    if input_data.nil? || input_data.empty?
      return { filtered_data: [], aggregations: {} }
    end

    header_line = input_data.first
    headers = header_line.split(',').map(&:strip)
    data_lines = input_data[1..] || [] # Use `1..` for concise slicing, `|| []` for safety if input_data had 0 elements (though covered by first check)

    filtered_rows_for_output = []
    all_passed_filter_rows_for_aggregation = []

    filter_lambda = transformations[:filter]
    select_columns = transformations[:select]
    aggregate_definitions = transformations[:aggregate]

    data_lines.each_slice(chunk_size) do |chunk|
      chunk.each do |line_string|
        values = line_string.split(',').map(&:strip)

        # Skip rows that don't match header count. A more robust CSV parser
        # would handle quoted fields, etc., but this is basic.
        next if values.length != headers.length

        original_row_data = headers.zip(values).to_h

        passes_filter = true
        if filter_lambda
          # Pass a copy to the filter lambda to prevent accidental modification
          # of the original_row_data by the lambda.
          passes_filter = filter_lambda.call(original_row_data.dup)
        end

        if passes_filter
          # Store a copy of the full, original-fielded row for aggregation purposes.
          # This ensures aggregations work on complete data before selection.
          all_passed_filter_rows_for_aggregation << original_row_data.dup

          row_for_final_output = original_row_data # By default, the full row is output.
          if select_columns
            # If select_columns is specified, build a new hash with only those columns.
            selected_data = {}
            select_columns.each do |col_name|
              if original_row_data.key?(col_name)
                selected_data[col_name] = original_row_data[col_name]
              end
            end
            row_for_final_output = selected_data
          else
            # If no select operation, the full row goes to output.
            # It should be a distinct object if original_row_data might be modified later,
            # but in this flow, original_row_data is fresh per loop.
            # However, all_passed_filter_rows_for_aggregation already got a dup.
            # If row_for_final_output is original_row_data, it is fine.
            # For strictness, one might dup here too: row_for_final_output = original_row_data.dup
            # But since original_row_data is not modified after this point in the loop,
            # and `select_columns` creates a new hash if it runs, this is okay.
            # If `select_columns` is nil, `row_for_final_output` refers to `original_row_data`.
            # This means `filtered_rows_for_output` might share objects if no select is done.
            # Example output implies string keys, which `to_h` provides.
            # To be absolutely safe and ensure `filtered_rows_for_output` contains independent objects:
            row_for_final_output = original_row_data.dup unless select_columns
          end
          filtered_rows_for_output << row_for_final_output
        end
      end
    end

    aggregations_result = {}
    if aggregate_definitions
      aggregate_definitions.each do |agg_key, agg_lambda|
        # The rows in all_passed_filter_rows_for_aggregation are already dups
        # of the initially parsed rows. So, they are safe to pass directly,
        # assuming aggregation lambdas are read-only regarding row content.
        aggregations_result[agg_key] = agg_lambda.call(all_passed_filter_rows_for_aggregation)
      end
    end

    {
      filtered_data: filtered_rows_for_output,
      aggregations: aggregations_result
    }
  end
end