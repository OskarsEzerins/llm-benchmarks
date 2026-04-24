require_relative 'model_variant_registry'

module Implementations
  class ModelSelectorService
    def initialize
      @prompt = TTY::Prompt.new
      @registry = ModelVariantRegistry.instance
    end

    def select
      @prompt.select(
        'Choose a model:',
        flat_choices,
        per_page: 30,
        filter: true,
        cycle: true,
        filter_hint: '(Start typing to filter)'
      )
    end

    def select_multiple
      @prompt.multi_select(
        'Choose models (use space to select, enter to confirm):',
        flat_choices,
        per_page: 50,
        filter: true,
        filter_hint: '(Start typing to filter)'
      )
    end

    private

    def flat_choices
      @registry.selection_entries(chat_models).map do |entry|
        {
          name: choice_label(entry),
          value: entry
        }
      end
    end

    def chat_models
      RubyLLM.models.refresh!

      RubyLLM.models.chat_models.filter do |model|
        model.id.include?('/')
      end
    end

    def choice_label(entry)
      [
        entry['base_model_name'],
        entry['variant_label'],
        "(#{entry['model_id'] || entry['base_model_id']})"
      ].compact.join(' / ')
    end
  end
end
