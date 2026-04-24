# frozen_string_literal: true

module Implementations
  class ChatBuilderService
    def self.build(implementation_metadata)
      new(implementation_metadata).build
    end

    def initialize(implementation_metadata)
      @implementation_metadata = implementation_metadata
    end

    def build
      chat = RubyLLM.chat(model: @implementation_metadata.fetch('model_id'))
      params = @implementation_metadata.dig('request', 'params') || @implementation_metadata['params'] || {}
      params.empty? ? chat : chat.with_params(deep_symbolize_keys(params))
    end

    private

    def deep_symbolize_keys(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, nested_value), result|
          result[key.to_sym] = deep_symbolize_keys(nested_value)
        end
      when Array
        value.map { |item| deep_symbolize_keys(item) }
      else
        value
      end
    end
  end
end
