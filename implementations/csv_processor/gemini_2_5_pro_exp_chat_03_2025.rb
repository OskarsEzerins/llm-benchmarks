# frozen_string_literal: true

class CsvProcessor
  # Processes CSV data provided as an array of strings, applying transformations.
  #
  # @param data [Array<String>] An array where the first string is the header
  #   and subsequent strings are data rows. Assumes simple comma separation
  #   without quoted fields containing commas.
  # @param transformations [Hash] A hash defining the transformations to apply.
  #   Supported keys:
  #   - :filter [Proc] A lambda/proc that takes a row hash and returns true
  #     if the row should be kept.
  #   - :select [Array<String>] An array of column names to include in the
  #     output rows.
  #   - :aggregate [Hash{Symbol => Proc}] A hash where keys are aggregation names
  #     and values are lambdas/procs that take an array of filtered row hashes
  #     and return the aggregated value.
  #
  # @return [Hash] A hash containing:
  #   - :filtered_data [Array<Hash>] An array of row hashes after filtering
  #     and selection.
  #   - :aggregations [Hash] A hash containing the results of the aggregation
  #     functions.
  def self.process(data, transformations = {})
    # Handle empty or nil data gracefully
    return { filtered_data: [], aggregations: {} } if data.nil? || data.empty?

    header_line = data.first
    # Basic CSV header parsing (splits by comma)
    headers = header_line.strip.split(',')
    data_lines = data.drop(1) # Get data rows, excluding the header

    filtered_rows = []

    # Process data lines row by row for memory efficiency during filtering
    data_lines.each do |line|
      # Basic CSV value parsing (splits by comma)
      values = line.strip.split(',')

      # Skip rows that don't match the header length
      next if values.length != headers.length

      # Create a hash representation of the row
      row_hash = headers.zip(values).to_h

      # Apply filter transformation if provided
      passes_filter = true # Default to true if no filter is specified
      if transformations[:filter] && transformations[:filter].is_a?(Proc)
        begin
          passes_filter = transformations[:filter].call(row_hash)
        rescue StandardError => e
          # Optionally handle or log errors during filter execution
          # For now, treat filter errors as filter failure
          warn "Filter error on row #{row_hash}: #{e.message}"
          passes_filter = false
        end
      end

      # Add row to filtered list if it passes the filter
      filtered_rows << row_hash if passes_filter
    end

    # Apply aggregation transformations on the filtered data
    aggregations_result = {}
    if transformations[:aggregate] && transformations[:aggregate].is_a?(Hash) && !filtered_rows.empty?
      transformations[:aggregate].each do |agg_name, agg_lambda|
        if agg_lambda.is_a?(Proc)
          begin
            aggregations_result[agg_name] = agg_lambda.call(filtered_rows)
          rescue StandardError => e
            # Optionally handle or log errors during aggregation
            warn "Aggregation error for '#{agg_name}': #{e.message}"
            aggregations_result[agg_name] = nil # Indicate error or default value
          end
        else
          warn "Invalid aggregation provided for '#{agg_name}': not a Proc."
        end
      end
    end

    # Apply select transformation on the filtered data
    selected_data = filtered_rows # Default to all filtered rows if no select is specified
    if transformations[:select] && transformations[:select].is_a?(Array)
      select_keys = transformations[:select]
      # Ensure selected keys are valid strings and exist in the headers
      valid_select_keys = select_keys.grep(String).select { |key| headers.include?(key) }

      # Map filtered rows to new hashes containing only selected keys
      selected_data = filtered_rows.map do |row|
        row.slice(*valid_select_keys)
      end
    end

    # Return the final structure
    {
      filtered_data: selected_data,
      aggregations: aggregations_result
    }
  end
end
