# frozen_string_literal: true

require "csv"

class CsvProcessor
  DEFAULT_CHUNK_SIZE = 1_000

  class << self
    def process(input_data, transformations = {})
      new(input_data, transformations).process
    end
  end

  def initialize(input_data, transformations = {})
    @data = input_data || []
    @transformations = transformations || {}

    @filter = option(:filter)
    @select_columns = normalize_select(option(:select))
    @chunk_size = normalize_chunk_size(option(:chunk_size))

    aggregate_definitions = option(:aggregate) || {}
    unless aggregate_definitions.is_a?(Hash)
      raise ArgumentError, "aggregate must be a Hash"
    end

    @row_aggregates = {}
    @stream_aggregates = {}

    aggregate_definitions.each do |name, definition|
      if definition.respond_to?(:call)
        @row_aggregates[name] = definition
      elsif definition.is_a?(Hash)
        init_fn = hash_option(definition, :init)
        step_fn = hash_option(definition, :step)
        finalize_fn = hash_option(definition, :finalize)

        unless init_fn.respond_to?(:call) && step_fn.respond_to?(:call)
          raise ArgumentError, "stream aggregate #{name.inspect} must provide callable :init and :step"
        end

        @stream_aggregates[name] = {
          init: init_fn,
          step: step_fn,
          finalize: finalize_fn
        }
      else
        raise ArgumentError, "invalid aggregate definition for #{name.inspect}"
      end
    end
  end

  def process
    return { filtered_data: [], aggregations: {} } if @data.empty?

    headers = parse_headers(@data.first)
    filtered_data = []
    row_aggregate_rows = @row_aggregates.empty? ? nil : []
    stream_states = initialize_stream_states

    chunk = []

    @data.each_with_index do |line, index|
      next if index.zero?

      chunk << line
      next if chunk.length < @chunk_size

      process_chunk(chunk, headers, filtered_data, row_aggregate_rows, stream_states)
      chunk.clear
    end

    process_chunk(chunk, headers, filtered_data, row_aggregate_rows, stream_states) unless chunk.empty?

    {
      filtered_data: filtered_data,
      aggregations: finalize_aggregations(row_aggregate_rows, stream_states)
    }
  end

  private

  def option(key)
    @transformations[key] || @transformations[key.to_s]
  end

  def hash_option(hash, key)
    hash[key] || hash[key.to_s]
  end

  def normalize_select(select_value)
    return nil if select_value.nil?

    Array(select_value).map(&:to_s)
  end

  def normalize_chunk_size(value)
    return DEFAULT_CHUNK_SIZE if value.nil?

    size = value.to_i
    size.positive? ? size : DEFAULT_CHUNK_SIZE
  end

  def parse_headers(header_line)
    headers = parse_line(header_line)
    if headers.nil? || headers.empty?
      raise ArgumentError, "CSV header row is missing or invalid"
    end

    headers.map(&:to_s)
  end

  def parse_line(line)
    return nil if line.nil?
    stripped = line.strip
    return nil if stripped.empty?

    CSV.parse_line(line)
  rescue CSV::MalformedCSVError => e
    raise ArgumentError, "Malformed CSV line: #{e.message}"
  end

  def build_row(headers, fields)
    headers.each_with_index.each_with_object({}) do |(header, i), row|
      row[header] = fields[i]
    end
  end

  def filter_passes?(row)
    return true unless @filter.respond_to?(:call)

    !!@filter.call(row)
  end

  def project_row(row)
    return row.dup if @select_columns.nil?

    @select_columns.each_with_object({}) do |column, projected|
      projected[column] = row[column]
    end
  end

  def initialize_stream_states
    @stream_aggregates.each_with_object({}) do |(name, cfg), states|
      states[name] = cfg[:init].call
    end
  end

  def apply_stream_aggregates(row, stream_states)
    @stream_aggregates.each do |name, cfg|
      current = stream_states[name]
      updated = cfg[:step].call(current, row)
      stream_states[name] = updated.nil? ? current : updated
    end
  end

  def process_chunk(lines, headers, filtered_data, row_aggregate_rows, stream_states)
    lines.each do |line|
      fields = parse_line(line)
      next if fields.nil?

      row = build_row(headers, fields)
      next unless filter_passes?(row)

      row_aggregate_rows << row if row_aggregate_rows
      apply_stream_aggregates(row, stream_states) unless @stream_aggregates.empty?
      filtered_data << project_row(row)
    end
  end

  def finalize_aggregations(row_aggregate_rows, stream_states)
    results = {}

    @row_aggregates.each do |name, callable|
      rows = row_aggregate_rows || []
      results[name] = callable.call(rows)
    end

    @stream_aggregates.each do |name, cfg|
      state = stream_states[name]
      finalize = cfg[:finalize]
      results[name] = finalize.respond_to?(:call) ? finalize.call(state) : state
    end

    results
  end
end