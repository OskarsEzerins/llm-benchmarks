# frozen_string_literal: true

require 'json'

module Implementations
  class ModelVariantRegistry
    CONFIG_FILE = File.expand_path('../../../config/model_variants.json', __dir__)
    MODEL_NAMES_FILE = File.expand_path('../../../config/model_names.json', __dir__)

    SOURCE_SUFFIX_PATTERN = /_(openrouter|openai_api|cursor_chat|cursor|vscode|web_chat|web)_\d{2}_\d{4}$|_\d{2}_\d{4}$/
    EFFORT_VALUES = %w[none minimal low medium high xhigh].freeze
    THINKING_VALUES = %w[off adaptive manual unknown].freeze
    OPENAI_REASONING_VARIANTS = [
      {
        'id' => 'default_effort_none',
        'label' => 'Default',
        'params' => {},
        'normalized' => { 'thinking_mode' => 'off', 'reasoning_effort' => 'none' }
      },
      {
        'id' => 'effort_low',
        'label' => 'Effort Low',
        'slug_suffix' => 'effort_low',
        'params' => { 'reasoning' => { 'effort' => 'low' } },
        'normalized' => { 'thinking_mode' => 'manual', 'reasoning_effort' => 'low' }
      },
      {
        'id' => 'effort_medium',
        'label' => 'Effort Medium',
        'slug_suffix' => 'effort_medium',
        'params' => { 'reasoning' => { 'effort' => 'medium' } },
        'normalized' => { 'thinking_mode' => 'manual', 'reasoning_effort' => 'medium' }
      },
      {
        'id' => 'effort_high',
        'label' => 'Effort High',
        'slug_suffix' => 'effort_high',
        'params' => { 'reasoning' => { 'effort' => 'high' } },
        'normalized' => { 'thinking_mode' => 'manual', 'reasoning_effort' => 'high' }
      }
    ].freeze
    ANTHROPIC_REASONING_VARIANTS = [
      {
        'id' => 'default_off_high',
        'label' => 'Default',
        'params' => {},
        'normalized' => { 'thinking_mode' => 'off', 'reasoning_effort' => 'high' }
      },
      {
        'id' => 'manual_budget_2048',
        'label' => 'Thinking Budget 2K',
        'slug_suffix' => 'budget_2048',
        'params' => { 'reasoning' => { 'max_tokens' => 2048 } },
        'normalized' => { 'thinking_mode' => 'manual', 'reasoning_effort' => 'medium', 'budget_tokens' => 2048 }
      },
      {
        'id' => 'manual_budget_8192',
        'label' => 'Thinking Budget 8K',
        'slug_suffix' => 'budget_8192',
        'params' => { 'reasoning' => { 'max_tokens' => 8192 } },
        'normalized' => { 'thinking_mode' => 'manual', 'reasoning_effort' => 'high', 'budget_tokens' => 8192 }
      }
    ].freeze

    def self.instance
      @instance ||= new
    end

    def initialize
      @config = load_json(CONFIG_FILE)
      @legacy_model_names = load_json(MODEL_NAMES_FILE)
      @variants = flatten_variants
      @variants_by_id = @variants.to_h { |variant| [variant['variant_id'], variant] }
      @variants_by_base_model = @variants.group_by { |variant| variant['base_model_id'] }
    end

    def configured_variants?
      @variants.any?
    end

    def base_models
      @variants_by_base_model.values
        .map(&:first)
        .sort_by { |variant| [variant['base_model_name'], variant['base_model_id']] }
    end

    def all_variants
      @variants
    end

    def variants_for_base(base_model_id)
      Array(@variants_by_base_model[base_model_id]).sort_by { |variant| variant['variant_label'] }
    end

    def find_variant(variant_id)
      variant = @variants_by_id[variant_id.to_s]
      deep_dup(variant) if variant
    end

    def resolve_selection(selection)
      case selection
      when Hash
        return deep_dup(selection) if selection['display_name'] && selection['implementation_slug_prefix']

        if selection['variant_id'] || selection[:variant_id]
          find_variant(selection['variant_id'] || selection[:variant_id])
        elsif selection['model_id'] || selection[:model_id]
          metadata_for_raw_model(selection['model_id'] || selection[:model_id])
        end
      when String
        find_variant(selection) || metadata_for_raw_model(selection)
      end
    end

    def metadata_for_raw_model(model_id)
      model_id = model_id.to_s
      base_name = format_model_id_display_name(model_id)
      slug_prefix = format_model_id_slug(model_id)
      normalized = {
        'thinking_mode' => 'unknown',
        'reasoning_effort' => 'unknown'
      }

      {
        'variant_id' => "raw::#{model_id}",
        'variant_key' => 'raw',
        'provider' => provider_from_model_id(model_id),
        'family' => infer_family(base_name, provider_from_model_id(model_id)),
        'base_model_id' => model_id,
        'model_id' => model_id,
        'base_model_name' => base_name,
        'variant_label' => 'Unconfigured Variant',
        'display_name' => "#{base_name} (Unconfigured Variant)",
        'implementation_slug_prefix' => slug_prefix,
        'legacy_slug_prefixes' => [slug_prefix],
        'source_tag' => 'openrouter',
        'params' => {},
        'request' => { 'provider' => 'openrouter', 'params' => {} },
        'normalized' => normalized,
        'param_summary' => build_param_summary(normalized),
        'configured_variant' => false
      }
    end

    def find_by_implementation(implementation)
      implementation = implementation.to_s
      base_slug = strip_source_suffix(implementation)

      variant = @variants
        .select { |entry| implementation_slug_prefixes(entry).include?(base_slug) }
        .max_by { |entry| entry['implementation_slug_prefix'].length }

      return deep_dup(variant.merge('implementation' => implementation)) if variant

      deep_dup(legacy_metadata_for_slug(implementation))
    end

    def selection_entries(models)
      Array(models).flat_map do |model|
        variants = variants_for_base(model.id)
        next variants if variants.any?

        auto_variants_for_model(model)
      end.sort_by { |entry| [entry['base_model_name'], selection_sort_key(entry)] }
    end

    def display_name_for_slug(implementation)
      find_by_implementation(implementation)&.dig('display_name') || implementation
    end

    private

    def flatten_variants
      Array(@config['base_models']).flat_map do |base_model|
        Array(base_model['variants']).map do |variant|
          normalized = normalize_normalized_fields(variant['normalized'] || {})
          variant_id = variant['variant_id'] || "#{base_model.fetch('default_slug_prefix')}__#{variant.fetch('id')}"
          slug_prefix = variant['implementation_slug_prefix'] || build_slug_prefix(base_model, variant)
          params = deep_dup(variant['params'] || {})

          {
            'variant_id' => variant_id,
            'variant_key' => variant.fetch('id'),
            'provider' => base_model.fetch('provider'),
            'family' => base_model['family'] || base_model.fetch('provider'),
            'base_model_id' => base_model.fetch('id'),
            'model_id' => variant['model_id'] || base_model.fetch('id'),
            'base_model_name' => base_model.fetch('name'),
            'variant_label' => variant.fetch('label'),
            'display_name' => build_display_name(base_model.fetch('name'), variant.fetch('label')),
            'implementation_slug_prefix' => slug_prefix,
            'legacy_slug_prefixes' => Array(variant['legacy_slug_prefixes']).map(&:to_s),
            'source_tag' => variant['source_tag'] || base_model['source_tag'] || 'openrouter',
            'params' => params,
            'request' => {
              'provider' => variant.dig('request', 'provider') || base_model['request_provider'] || 'openrouter',
              'params' => params
            },
            'normalized' => normalized,
            'param_summary' => begin
              configured_summary = Array(variant['param_summary']).compact
              configured_summary.empty? ? build_param_summary(normalized) : configured_summary
            end,
            'configured_variant' => true
          }
        end
      end.sort_by { |variant| [variant['base_model_name'], variant['variant_label']] }
    end

    def build_slug_prefix(base_model, variant)
      [base_model.fetch('default_slug_prefix'), variant['slug_suffix']].compact.reject(&:empty?).join('_')
    end

    def build_display_name(base_model_name, variant_label)
      "#{base_model_name} (#{variant_label})"
    end

    def auto_variants_for_model(model)
      template = auto_variant_templates_for_model(model)
      return [metadata_for_raw_model(model.id)] unless template

      template.map do |variant|
        build_auto_variant(model, variant)
      end
    end

    def auto_variant_templates_for_model(model)
      metadata = model.respond_to?(:metadata) ? model.metadata : {}
      supported_parameters = Array(metadata['supported_parameters'])
      return nil unless model.respond_to?(:reasoning?) && model.reasoning?
      return nil unless supported_parameters.include?('reasoning') || supported_parameters.include?('include_reasoning')

      provider_namespace = model.id.to_s.split('/').first

      case provider_namespace
      when 'openai'
        OPENAI_REASONING_VARIANTS
      when 'anthropic'
        ANTHROPIC_REASONING_VARIANTS
      else
        nil
      end
    end

    def build_auto_variant(model, variant)
      base_model_name = model.respond_to?(:name) ? model.name.to_s : format_model_id_display_name(model.id)
      provider = provider_from_model_id(model.id)
      family = infer_family(base_model_name, provider)
      slug_prefix_base = format_model_id_slug(model.id)
      slug_suffix = variant['slug_suffix']
      implementation_slug_prefix = [slug_prefix_base, slug_suffix].compact.reject(&:empty?).join('_')
      normalized = normalize_normalized_fields(variant['normalized'] || {})
      variant_label = variant['label']

      {
        'variant_id' => "auto::#{model.id}::#{variant.fetch('id')}",
        'variant_key' => variant.fetch('id'),
        'provider' => provider,
        'family' => family,
        'base_model_id' => model.id,
        'model_id' => model.id,
        'base_model_name' => base_model_name,
        'variant_label' => variant_label,
        'display_name' => build_display_name(base_model_name, variant_label),
        'implementation_slug_prefix' => implementation_slug_prefix,
        'legacy_slug_prefixes' => [slug_prefix_base],
        'source_tag' => 'openrouter',
        'params' => deep_dup(variant['params'] || {}),
        'request' => {
          'provider' => 'openrouter',
          'params' => deep_dup(variant['params'] || {})
        },
        'normalized' => normalized,
        'param_summary' => build_param_summary(normalized),
        'configured_variant' => false
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
      entry = @legacy_model_names[implementation] || @legacy_model_names[base_slug]
      raw_display_name = entry.is_a?(Hash) ? entry['display_name'] : format_display_name(base_slug)
      provider = entry.is_a?(Hash) ? entry['provider'] : 'Other'
      base_model_name = raw_display_name.to_s.sub(/\s*\((?:Thinking|Reasoning)\)\s*$/i, '').strip
      normalized = infer_legacy_normalized_fields(base_slug, raw_display_name)
      variant_label = build_legacy_variant_label(normalized)

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
      thinking_mode =
        if haystack.include?('adaptive')
          'adaptive'
        elsif haystack.include?('thinking') || haystack.include?('reasoning')
          'manual'
        else
          'unknown'
        end

      effort = EFFORT_VALUES.find { |value| haystack.match?(/(?:^|[_\s(])#{Regexp.escape(value)}(?:$|[_\s)])/i) } || 'unknown'

      {
        'thinking_mode' => thinking_mode,
        'reasoning_effort' => effort
      }
    end

    def build_legacy_variant_label(normalized)
      return 'Legacy Variant' if normalized['thinking_mode'] == 'unknown' && normalized['reasoning_effort'] == 'unknown'

      build_param_summary(normalized).join(' • ')
    end

    def implementation_slug_prefixes(entry)
      ([entry['implementation_slug_prefix']] + Array(entry['legacy_slug_prefixes'])).compact.uniq
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

    def provider_from_model_id(model_id)
      provider_slug = model_id.to_s.split('/').first.to_s

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

      variant_label
    end
  end
end
