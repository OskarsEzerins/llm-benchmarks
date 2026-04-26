# frozen_string_literal: true

module Implementations
  module ModelVariantFormatting
    module_function

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
        provider_slug == 'openai' && index.zero? && part.match?(/\Agpt\z/i) ? 'GPT' : part.capitalize
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

    def build_param_summary(normalized)
      summary = []
      summary << "Thinking: #{titleize(normalized['thinking_mode'])}" if normalized['thinking_mode']
      summary << "Effort: #{titleize(normalized['reasoning_effort'])}" if normalized['reasoning_effort']
      summary << "Budget: #{normalized['budget_tokens']}" if normalized['budget_tokens']
      summary
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
