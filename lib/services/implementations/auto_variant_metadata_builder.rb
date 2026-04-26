# frozen_string_literal: true

require 'json'
require_relative 'model_variant_formatting'

module Implementations
  class AutoVariantMetadataBuilder
    EFFORT_VALUES = %w[none minimal low medium high xhigh].freeze
    THINKING_VALUES = %w[off adaptive manual unknown].freeze

    def self.build(attributes)
      new(attributes).build
    end

    def initialize(attributes)
      @attributes = attributes
    end

    def build
      identity_fields
        .merge(storage_fields)
        .merge(request_fields)
        .merge(configuration_fields)
    end

    private

    attr_reader :attributes

    def identity_fields
      {
        'variant_id' => "auto::#{model_id}::#{variant.fetch('id')}",
        'variant_key' => variant.fetch('id'),
        'provider' => attributes.fetch(:provider),
        'family' => attributes.fetch(:family),
        'base_model_id' => model_id,
        'model_id' => model_id,
        'base_model_name' => base_model_name,
        'variant_label' => variant.fetch('label'),
        'display_name' => ModelVariantFormatting.build_display_name(base_model_name, variant.fetch('label'))
      }
    end

    def storage_fields
      {
        'implementation_slug_prefix' => implementation_slug_prefix,
        'legacy_slug_prefixes' => [slug_prefix_base],
        'source_tag' => 'openrouter'
      }
    end

    def request_fields
      {
        'params' => params,
        'request' => {
          'provider' => 'openrouter',
          'params' => params
        }
      }
    end

    def configuration_fields
      {
        'normalized' => normalized,
        'param_summary' => ModelVariantFormatting.build_param_summary(normalized),
        'configured_variant' => attributes.fetch(:configured_variant)
      }
    end

    def model_id
      attributes.fetch(:model_id)
    end

    def base_model_name
      attributes.fetch(:base_model_name)
    end

    def variant
      attributes.fetch(:variant)
    end

    def slug_prefix_base
      @slug_prefix_base ||= ModelVariantFormatting.format_model_id_slug(model_id)
    end

    def implementation_slug_prefix
      @implementation_slug_prefix ||= [slug_prefix_base, variant['slug_suffix']].compact.reject(&:empty?).join('_')
    end

    def normalized
      @normalized ||= normalize_normalized_fields(variant['normalized'] || {})
    end

    def params
      @params ||= deep_dup(variant['params'] || {})
    end

    def normalize_normalized_fields(normalized)
      thinking_mode = normalized['thinking_mode'].to_s
      reasoning_effort = normalized['reasoning_effort'].to_s

      {
        'thinking_mode' => THINKING_VALUES.include?(thinking_mode) ? thinking_mode : 'unknown',
        'reasoning_effort' => EFFORT_VALUES.include?(reasoning_effort) ? reasoning_effort : 'unknown',
        'budget_tokens' => normalized['budget_tokens']
      }.compact
    end

    def deep_dup(value)
      JSON.parse(JSON.generate(value)) if value
    rescue StandardError
      value
    end
  end
end
