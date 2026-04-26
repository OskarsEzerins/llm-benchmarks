# frozen_string_literal: true

require 'json'
require_relative 'model_variant_formatting'

module Implementations
  class LegacyModelMetadataBuilder
    SOURCE_SUFFIX_PATTERN = /_(openrouter|openai_api|cursor_chat|cursor|vscode|web_chat|web)_\d{2}_\d{4}$|_\d{2}_\d{4}$/
    EFFORT_VALUES = %w[none minimal low medium high xhigh].freeze

    def initialize(model_names)
      @model_names = model_names
    end

    def find_by_implementation(implementation)
      implementation = implementation.to_s
      entry = legacy_model_name_entry(implementation)
      metadata = entry.is_a?(Hash) ? entry['metadata'] : nil

      return deep_dup(metadata.merge('implementation' => implementation)) if metadata

      deep_dup(legacy_metadata_for_slug(implementation))
    end

    private

    def legacy_metadata_for_slug(implementation)
      base_slug = strip_source_suffix(implementation)
      entry = legacy_model_name_entry(implementation)
      raw_display_name = legacy_display_name(entry, base_slug)
      provider = entry.is_a?(Hash) ? entry['provider'] : 'Other'
      normalized = infer_legacy_normalized_fields(base_slug, raw_display_name)

      legacy_metadata_payload(
        implementation: implementation,
        base_slug: base_slug,
        raw_display_name: raw_display_name,
        provider: provider,
        normalized: normalized
      )
    end

    def legacy_metadata_payload(implementation:, base_slug:, raw_display_name:, provider:, normalized:)
      base_model_name = raw_display_name.to_s.sub(/\s*\([^)]*\)\s*$/, '').strip

      {
        'variant_id' => "legacy::#{base_slug}",
        'variant_key' => 'legacy',
        'provider' => provider,
        'family' => ModelVariantFormatting.infer_family(raw_display_name, provider),
        'base_model_id' => base_slug,
        'model_id' => nil,
        'base_model_name' => base_model_name.empty? ? raw_display_name : base_model_name,
        'variant_label' => build_legacy_variant_label(normalized),
        'display_name' => raw_display_name,
        'implementation_slug_prefix' => base_slug,
        'legacy_slug_prefixes' => [base_slug],
        'source_tag' => source_tag_from_slug(implementation),
        'params' => {},
        'request' => { 'provider' => 'openrouter', 'params' => {} },
        'normalized' => normalized,
        'param_summary' => ModelVariantFormatting.build_param_summary(normalized),
        'configured_variant' => false,
        'implementation' => implementation
      }
    end

    def legacy_display_name(entry, base_slug)
      return entry['display_name'] if entry.is_a?(Hash)

      ModelVariantFormatting.format_display_name(base_slug)
    end

    def infer_legacy_normalized_fields(base_slug, display_name)
      haystack = "#{base_slug} #{display_name}".downcase
      budget_tokens = haystack[/budget[_\s-]*(\d+)/, 1]&.to_i

      {
        'thinking_mode' => infer_thinking_mode(haystack, budget_tokens),
        'reasoning_effort' => infer_reasoning_effort(haystack, budget_tokens),
        'budget_tokens' => budget_tokens
      }.compact
    end

    def infer_thinking_mode(haystack, budget_tokens)
      return 'adaptive' if haystack.include?('adaptive')
      return 'manual' if manual_thinking?(haystack, budget_tokens)

      'unknown'
    end

    def manual_thinking?(haystack, budget_tokens)
      budget_tokens || %w[thinking reasoning effort].any? { |needle| haystack.include?(needle) }
    end

    def infer_reasoning_effort(haystack, budget_tokens)
      explicit_effort = EFFORT_VALUES.find do |value|
        haystack.match?(/(?:^|[_\s(])#{Regexp.escape(value)}(?:$|[_\s)])/i)
      end
      return explicit_effort if explicit_effort
      return 'high' if budget_tokens && budget_tokens >= 8192
      return 'medium' if budget_tokens

      'unknown'
    end

    def build_legacy_variant_label(normalized)
      return 'Legacy Variant' if legacy_unknown?(normalized)

      ModelVariantFormatting.build_param_summary(normalized).join(' • ')
    end

    def legacy_unknown?(normalized)
      normalized['thinking_mode'] == 'unknown' && normalized['reasoning_effort'] == 'unknown'
    end

    def legacy_model_name_entry(implementation)
      implementation = implementation.to_s
      @model_names[implementation] || @model_names[strip_source_suffix(implementation)]
    end

    def strip_source_suffix(slug)
      slug.to_s.sub(SOURCE_SUFFIX_PATTERN, '')
    end

    def source_tag_from_slug(slug)
      slug.to_s[SOURCE_SUFFIX_PATTERN]&.sub(/^_/, '')&.sub(/_\d{2}_\d{4}$/, '') || 'openrouter'
    end

    def deep_dup(value)
      JSON.parse(JSON.generate(value)) if value
    rescue StandardError
      value
    end
  end
end
