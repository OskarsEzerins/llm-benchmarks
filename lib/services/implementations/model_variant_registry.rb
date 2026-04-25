# frozen_string_literal: true

require 'json'

module Implementations
  class ModelVariantRegistry
    MODEL_NAMES_FILE = File.expand_path('../../../config/model_names.json', __dir__)

    SOURCE_SUFFIX_PATTERN = /_(openrouter|openai_api|cursor_chat|cursor|vscode|web_chat|web)_\d{2}_\d{4}$|_\d{2}_\d{4}$/
    EFFORT_VALUES = %w[none minimal low medium high xhigh].freeze
    THINKING_VALUES = %w[off adaptive manual unknown].freeze
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

    def self.instance
      @instance ||= new
    end

    def initialize
      @legacy_model_names = load_json(MODEL_NAMES_FILE)
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
      base_name = format_model_id_display_name(model_id)
      build_variant_metadata(
        model_id: model_id,
        base_model_name: base_name,
        provider: provider_from_model_id(model_id),
        family: infer_family(base_name, provider_from_model_id(model_id)),
        variant: DEFAULT_VARIANT,
        configured_variant: false
      )
    end

    def find_by_implementation(implementation)
      implementation = implementation.to_s
      entry = legacy_model_name_entry(implementation)

      metadata = entry.is_a?(Hash) ? entry['metadata'] : nil
      return deep_dup(metadata.merge('implementation' => implementation)) if metadata

      deep_dup(legacy_metadata_for_slug(implementation))
    end

    def selection_entries(models)
      Array(models).flat_map { |model| auto_variants_for_model(model) }
                   .sort_by { |entry| [entry['base_model_name'], selection_sort_key(entry)] }
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
      base_model_name = model_display_name(model)
      provider = provider_from_model_id(model.id)

      build_variant_metadata(
        model_id: model.id,
        base_model_name: base_model_name,
        provider: provider,
        family: infer_family(base_model_name, provider),
        variant: variant,
        configured_variant: false
      )
    end

    def build_variant_metadata(model_id:, base_model_name:, provider:, family:, variant:, configured_variant:)
      slug_prefix_base = format_model_id_slug(model_id)
      slug_suffix = variant['slug_suffix']
      implementation_slug_prefix = [slug_prefix_base, slug_suffix].compact.reject(&:empty?).join('_')
      normalized = normalize_normalized_fields(variant['normalized'] || {})
      params = deep_dup(variant['params'] || {})

      {
        'variant_id' => "auto::#{model_id}::#{variant.fetch('id')}",
        'variant_key' => variant.fetch('id'),
        'provider' => provider,
        'family' => family,
        'base_model_id' => model_id,
        'model_id' => model_id,
        'base_model_name' => base_model_name,
        'variant_label' => variant.fetch('label'),
        'display_name' => build_display_name(base_model_name, variant.fetch('label')),
        'implementation_slug_prefix' => implementation_slug_prefix,
        'legacy_slug_prefixes' => [slug_prefix_base],
        'source_tag' => 'openrouter',
        'params' => params,
        'request' => {
          'provider' => 'openrouter',
          'params' => params
        },
        'normalized' => normalized,
        'param_summary' => build_param_summary(normalized),
        'configured_variant' => configured_variant
      }
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

    def build_param_summary(normalized)
      summary = []
      summary << "Thinking: #{titleize(normalized['thinking_mode'])}" if normalized['thinking_mode']
      summary << "Effort: #{titleize(normalized['reasoning_effort'])}" if normalized['reasoning_effort']
      summary << "Budget: #{normalized['budget_tokens']}" if normalized['budget_tokens']
      summary
    end

    def legacy_metadata_for_slug(implementation)
      base_slug = strip_source_suffix(implementation)
      entry = legacy_model_name_entry(implementation)
      raw_display_name = entry.is_a?(Hash) ? entry['display_name'] : format_display_name(base_slug)
      provider = entry.is_a?(Hash) ? entry['provider'] : 'Other'
      normalized = infer_legacy_normalized_fields(base_slug, raw_display_name)
      variant_label = build_legacy_variant_label(normalized)
      base_model_name = raw_display_name.to_s.sub(/\s*\([^)]*\)\s*$/, '').strip

      {
        'variant_id' => "legacy::#{base_slug}",
        'variant_key' => 'legacy',
        'provider' => provider,
        'family' => infer_family(raw_display_name, provider),
        'base_model_id' => base_slug,
        'model_id' => nil,
        'base_model_name' => base_model_name.empty? ? raw_display_name : base_model_name,
        'variant_label' => variant_label,
        'display_name' => raw_display_name,
        'implementation_slug_prefix' => base_slug,
        'legacy_slug_prefixes' => [base_slug],
        'source_tag' => source_tag_from_slug(implementation),
        'params' => {},
        'request' => { 'provider' => 'openrouter', 'params' => {} },
        'normalized' => normalized,
        'param_summary' => build_param_summary(normalized),
        'configured_variant' => false,
        'implementation' => implementation
      }
    end

    def infer_legacy_normalized_fields(base_slug, display_name)
      haystack = "#{base_slug} #{display_name}".downcase
      budget_tokens = haystack[/budget[_\s-]*(\d+)/, 1]&.to_i
      thinking_mode =
        if haystack.include?('adaptive')
          'adaptive'
        elsif haystack.include?('thinking') || haystack.include?('reasoning') || haystack.include?('effort') || budget_tokens
          'manual'
        else
          'unknown'
        end

      effort = EFFORT_VALUES.find { |value| haystack.match?(/(?:^|[_\s(])#{Regexp.escape(value)}(?:$|[_\s)])/i) }
      effort ||= budget_tokens && budget_tokens >= 8192 ? 'high' : nil
      effort ||= budget_tokens ? 'medium' : 'unknown'

      {
        'thinking_mode' => thinking_mode,
        'reasoning_effort' => effort,
        'budget_tokens' => budget_tokens
      }.compact
    end

    def build_legacy_variant_label(normalized)
      return 'Legacy Variant' if normalized['thinking_mode'] == 'unknown' && normalized['reasoning_effort'] == 'unknown'

      build_param_summary(normalized).join(' • ')
    end

    def legacy_model_name_entry(implementation)
      implementation = implementation.to_s
      @legacy_model_names[implementation] || @legacy_model_names[strip_source_suffix(implementation)]
    end

    def strip_source_suffix(slug)
      slug.to_s.sub(SOURCE_SUFFIX_PATTERN, '')
    end

    def source_tag_from_slug(slug)
      slug.to_s[SOURCE_SUFFIX_PATTERN]&.sub(/^_/, '')&.sub(/_\d{2}_\d{4}$/, '') || 'openrouter'
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

    def model_display_name(model)
      raw_name = model.respond_to?(:name) ? model.name.to_s : ''
      name = raw_name.include?(':') ? raw_name.split(':', 2).last.strip : raw_name.strip
      name.empty? ? format_model_id_display_name(model.id) : name
    end

    def provider_from_model_id(model_id)
      provider_slug = model_id.to_s.split('/').first.to_s.delete_prefix('~')

      case provider_slug
      when 'openai' then 'OpenAI'
      when 'anthropic' then 'Anthropic'
      when 'google' then 'Google'
      when 'deepseek' then 'DeepSeek'
      when 'mistralai' then 'Mistral'
      when 'meta-llama', 'meta' then 'Meta'
      when 'x-ai', 'xai' then 'xAI'
      else
        provider_slug.empty? ? 'Other' : provider_slug.split(/[-_]/).map(&:capitalize).join(' ')
      end
    end

    def format_model_id_display_name(model_id)
      provider_slug, model_slug = model_id.to_s.split('/', 2)
      provider_slug = provider_slug.to_s.delete_prefix('~')
      formatted = model_slug.to_s.tr('._-', ' ').split.map.with_index do |part, index|
        if provider_slug == 'openai' && index.zero? && part.match?(/\Agpt\z/i)
          'GPT'
        else
          part.capitalize
        end
      end.join(' ')
      formatted.empty? ? model_id : formatted
    end

    def format_model_id_slug(model_id)
      provider_slug, model_slug = model_id.to_s.split('/', 2)
      provider_slug = provider_slug.to_s.delete_prefix('~')
      model_part = model_slug.to_s.tr('-.:() ', '_').downcase
      return "openai_#{model_part.gsub('gpt', '')}".squeeze('_') if provider_slug == 'openai'

      model_part.squeeze('_')
    end

    def infer_family(base_name, provider)
      name = base_name.to_s.downcase
      return 'Claude' if name.include?('claude')
      return 'Gemini' if name.include?('gemini')

      provider
    end

    def build_display_name(base_model_name, variant_label)
      return base_model_name if variant_label == 'Default'

      "#{base_model_name} (#{variant_label})"
    end

    def format_display_name(slug)
      slug
        .split('_')
        .map(&:capitalize)
        .join(' ')
    end

    def titleize(value)
      value.to_s.split('_').map(&:capitalize).join(' ')
    end

    def selection_sort_key(entry)
      variant_label = entry['variant_label'].to_s
      return '000_default' if variant_label == 'Default'
      return '050_none' if variant_label.end_with?('None')
      return '100_low' if variant_label.end_with?('Low')
      return '200_medium' if variant_label.end_with?('Medium')
      return '300_high' if variant_label.end_with?('High')
      return '400_xhigh' if variant_label.end_with?('XHigh')

      variant_label
    end
  end
end
