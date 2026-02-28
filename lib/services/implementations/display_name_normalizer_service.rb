# frozen_string_literal: true

require 'json'

module Implementations
  # Normalizes raw OpenRouter model names into clean display names.
  class DisplayNameNormalizerService
    NORMALIZATION_MODEL = 'claude-haiku-4-5'

    def self.normalize(model_id:, raw_name:, provider:)
      new(model_id:, raw_name:, provider:).normalize
    end

    def initialize(model_id:, raw_name:, provider:)
      @model_id = model_id
      @raw_name = raw_name
      @provider = provider
    end

    def normalize
      response = RubyLLM.chat(model: NORMALIZATION_MODEL, provider: :openrouter).ask(prompt)
      result = response.content.strip
      result.empty? || result.include?("\n") ? fallback : result
    rescue StandardError => e
      puts "Warning: display name normalization failed (#{e.message}), using raw name"
      fallback
    end

    private

    def prompt
      <<~PROMPT
        Return a clean display name for this AI model. Rules:
        - Replace hyphens with spaces
        - Strip trailing date suffixes (e.g. "05-20", "0324", "2024-07-18")
        - Strip "Provider: " colon prefix if present
        - Keep the provider brand in the name only if it is part of the model identity (e.g. DeepSeek, Mistral, Qwen, Gemini, Claude, Llama, Grok) — omit it if it merely duplicates the provider badge (e.g. "OpenAI" for OpenAI models)
        - Preserve version numbers, size suffixes, and qualifiers like (High)
        - Preserve the original capitalisation of the first character (e.g. "o4-mini" → "o4 mini", not "O4 mini")
        - Return only the display name, nothing else

        Examples:
          openai/gpt-5.3-codex   [OpenAI]  → GPT 5.3 Codex
          openai/o4-mini         [OpenAI]  → o4 mini
          deepseek/deepseek-r2   [DeepSeek] → DeepSeek R2
          mistralai/mistral-large-3 [Mistral] → Mistral Large 3
          google/gemini-3.5-flash-2024-07-18 [Google] → Gemini 3.5 Flash
          qwen/qwen4-coder       [Qwen]    → Qwen4 Coder

        Provider: #{@provider}
        Model ID: #{@model_id}
        Raw name: #{@raw_name}
      PROMPT
    end

    def fallback
      name = @raw_name.dup
      name = name.split(': ', 2).last if name.include?(': ')
      name.tr('-', ' ')
    end
  end
end
