require_relative 'model_variant_registry'

module Implementations
  class ModelSelectorService
    def initialize
      @prompt = TTY::Prompt.new
      @registry = ModelVariantRegistry.instance
    end

    def select
      mode = selection_mode
      return select_raw_model unless mode == :configured_variant

      base_model = @prompt.select(
        'Choose a base model:',
        base_model_choices,
        per_page: 20,
        filter: true,
        cycle: true,
        filter_hint: '(Start typing to filter)'
      )

      variant_id = @prompt.select(
        'Choose a parameter preset:',
        variant_choices_for_base(base_model),
        per_page: 20,
        filter: true,
        cycle: true,
        filter_hint: '(Start typing to filter)'
      )

      { 'variant_id' => variant_id }
    end

    def select_multiple
      mode = selection_mode
      return select_multiple_raw_models unless mode == :configured_variant

      @prompt.multi_select(
        'Choose variants (use space to select, enter to confirm):',
        all_variant_choices,
        per_page: 50,
        filter: true,
        filter_hint: '(Start typing to filter)'
      ).map { |variant_id| { 'variant_id' => variant_id } }
    end

    private

    def selection_mode
      return :raw_model unless @registry.configured_variants?

      @prompt.select(
        'Choose selection mode:',
        [
          { name: 'Configured benchmark variants', value: :configured_variant },
          { name: 'Raw model IDs (no preset metadata)', value: :raw_model }
        ]
      )
    end

    def select_raw_model
      { 'model_id' => @prompt.select(
        'Choose a model:',
        raw_model_choices,
        per_page: 20,
        filter: true,
        cycle: true,
        filter_hint: '(Start typing to filter)'
      ) }
    end

    def select_multiple_raw_models
      @prompt.multi_select(
        'Choose models (use space to select, enter to confirm):',
        raw_model_choices,
        per_page: 50,
        filter: true,
        filter_hint: '(Start typing to filter)'
      ).map { |model_id| { 'model_id' => model_id } }
    end

    def base_model_choices
      @registry.base_models.map do |variant|
        {
          name: "#{variant['base_model_name']} (#{variant['base_model_id']})",
          value: variant['base_model_id']
        }
      end
    end

    def variant_choices_for_base(base_model_id)
      @registry.variants_for_base(base_model_id).map do |variant|
        {
          name: "#{variant['variant_label']} (#{variant['implementation_slug_prefix']})",
          value: variant['variant_id']
        }
      end
    end

    def all_variant_choices
      @registry.all_variants.map do |variant|
        {
          name: "#{variant['base_model_name']} / #{variant['variant_label']}",
          value: variant['variant_id']
        }
      end
    end

    def raw_model_choices
      chat_models.map do |model|
        {
          name: "#{model.name} (#{model.id})",
          value: model.id
        }
      end
    end

    def chat_models
      RubyLLM.models.refresh!

      RubyLLM.models.chat_models.filter do |model|
        model.id.include?('/')
      end
    end
  end
end
