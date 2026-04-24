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
      chat = apply_thinking(chat)

      params = residual_params
      params.empty? ? chat : chat.with_params(**deep_symbolize_keys(params))
    end

    private

    def apply_thinking(chat)
      reasoning = raw_params['reasoning']
      return chat unless reasoning.is_a?(Hash)

      effort = reasoning['effort'] || reasoning[:effort]
      budget = reasoning['max_tokens'] || reasoning[:max_tokens] || reasoning['budget'] || reasoning[:budget]
      return chat if effort.nil? && budget.nil?

      kwargs = {}
      kwargs[:effort] = effort.to_sym if effort
      kwargs[:budget] = budget if budget
      chat.with_thinking(**kwargs)
    end

    def raw_params
      @implementation_metadata.dig('request', 'params') || @implementation_metadata['params'] || {}
    end

    def residual_params
      params = deep_symbolize_keys(raw_params)
      params.delete(:reasoning)
      params
    end

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
