module Implementations
  class ModelSelectorService
    def initialize
      @prompt = TTY::Prompt.new
    end

    def select
      choices = chat_models.map do |model|
        {
          name: "#{model.name} (#{model.id})",
          value: model.id
        }
      end

      @prompt.select(
        'Choose a model:',
        choices,
        per_page: 20,
        filter: true,
        cycle: true,
        filter_hint: '(Start typing to filter)'
      )
    end

    private

    def chat_models
      RubyLLM.models.refresh!

      RubyLLM.models.chat_models.filter do |model|
        model.id.include?('/')
      end
    end
  end
end
