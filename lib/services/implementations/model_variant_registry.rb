# frozen_string_literal: true

require 'json'
require 'singleton'
require_relative 'auto_variant_metadata_builder'
require_relative 'legacy_model_metadata_builder'
require_relative 'model_variant_formatting'

module Implementations
  class ModelVariantRegistry
    include Singleton

    MODEL_NAMES_FILE = File.expand_path('../../../config/model_names.json', __dir__)

    AUTO_THINKING_VARIANTS = [
      {
        'id' => 'default',
        'label' => 'Default',
        'params' => {},
        'normalized' => { 'thinking_mode' => 'off', 'reasoning_effort' => 'none' }
      },
      {
        'id' => 'effort_none',
        'label' => 'Thinking None',
        'slug_suffix' => 'effort_none',
        'params' => { 'reasoning' => { 'effort' => 'none' } },
        'normalized' => { 'thinking_mode' => 'off', 'reasoning_effort' => 'none' }
      },
      {
        'id' => 'effort_low',
        'label' => 'Thinking Low',
        'slug_suffix' => 'effort_low',
        'params' => { 'reasoning' => { 'effort' => 'low' } },
        'normalized' => { 'thinking_mode' => 'manual', 'reasoning_effort' => 'low' }
      },
      {
        'id' => 'effort_medium',
        'label' => 'Thinking Medium',
        'slug_suffix' => 'effort_medium',
        'params' => { 'reasoning' => { 'effort' => 'medium' } },
        'normalized' => { 'thinking_mode' => 'manual', 'reasoning_effort' => 'medium' }
      },
      {
        'id' => 'effort_high',
        'label' => 'Thinking High',
        'slug_suffix' => 'effort_high',
        'params' => { 'reasoning' => { 'effort' => 'high' } },
        'normalized' => { 'thinking_mode' => 'manual', 'reasoning_effort' => 'high' }
      },
      {
        'id' => 'effort_xhigh',
        'label' => 'Thinking XHigh',
        'slug_suffix' => 'effort_xhigh',
        'params' => { 'reasoning' => { 'effort' => 'xhigh' } },
        'normalized' => { 'thinking_mode' => 'manual', 'reasoning_effort' => 'xhigh' }
      }
    ].freeze

    DEFAULT_VARIANT = AUTO_THINKING_VARIANTS.first.freeze

    def initialize
      @legacy_model_names = load_json(MODEL_NAMES_FILE)
      @legacy_metadata_builder = LegacyModelMetadataBuilder.new(@legacy_model_names)
    end

    def resolve_selection(selection)
      case selection
      when Hash
        return deep_dup(selection) if selection['display_name'] && selection['implementation_slug_prefix']

        if selection['model_id'] || selection[:model_id]
          metadata_for_raw_model(selection['model_id'] || selection[:model_id])
        end
      when String
        metadata_for_raw_model(selection)
      end
    end

    def metadata_for_raw_model(model_id)
      model_id = model_id.to_s
      base_name = ModelVariantFormatting.format_model_id_display_name(model_id)
      provider = ModelVariantFormatting.provider_from_model_id(model_id)

      build_variant_metadata(
        model_id: model_id,
        base_model_name: base_name,
        provider: provider,
        family: ModelVariantFormatting.infer_family(base_name, provider),
        variant: DEFAULT_VARIANT,
        configured_variant: false
      )
    end

    def find_by_implementation(implementation)
      @legacy_metadata_builder.find_by_implementation(implementation)
    end

    def selection_entries(models)
      Array(models).flat_map { |model| auto_variants_for_model(model) }
                   .sort_by { |entry| [entry['base_model_name'], ModelVariantFormatting.selection_sort_key(entry)] }
    end

    def display_name_for_slug(implementation)
      find_by_implementation(implementation)&.dig('display_name') || implementation
    end

    private

    def auto_variants_for_model(model)
      variants = supports_reasoning?(model) ? AUTO_THINKING_VARIANTS : [DEFAULT_VARIANT]

      variants.map do |variant|
        build_auto_variant(model, variant)
      end
    end

    def supports_reasoning?(model)
      supported_parameters = supported_parameters_for(model)

      return true if supported_parameters.include?('reasoning') || supported_parameters.include?('include_reasoning')

      model.respond_to?(:reasoning?) && model.reasoning?
    end

    def supported_parameters_for(model)
      metadata = model.respond_to?(:metadata) ? model.metadata : {}
      params = metadata[:supported_parameters] || metadata['supported_parameters']
      Array(params).map(&:to_s)
    rescue StandardError
      []
    end

    def build_auto_variant(model, variant)
      base_model_name = ModelVariantFormatting.model_display_name(model)
      provider = ModelVariantFormatting.provider_from_model_id(model.id)

      build_variant_metadata(
        model_id: model.id,
        base_model_name: base_model_name,
        provider: provider,
        family: ModelVariantFormatting.infer_family(base_model_name, provider),
        variant: variant,
        configured_variant: false
      )
    end

    def build_variant_metadata(attributes)
      AutoVariantMetadataBuilder.build(attributes)
    end

    def load_json(path)
      return {} unless File.exist?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError
      {}
    end

    def deep_dup(value)
      JSON.parse(JSON.generate(value)) if value
    rescue StandardError
      value
    end
  end
end
