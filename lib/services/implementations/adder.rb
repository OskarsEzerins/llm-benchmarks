require_relative 'model_selector_service'
require_relative 'prompt_processor_service'
require_relative 'code_saver_service'
require_relative '../benchmark_type_selector_service'

module Implementations
  class Adder
    def initialize
      @prompt = TTY::Prompt.new
    end

    def add
      benchmark_type = ::BenchmarkTypeSelectorService.new.select
      return {} unless benchmark_type

      selection_type = @prompt.select(
        'How would you like to select models?',
        [
          { name: 'Single model', value: :single },
          { name: 'Multiple models', value: :multiple }
        ]
      )

      case selection_type
      when :single
        selections = [ModelSelectorService.new.select]
        return {} unless selections.first
      when :multiple
        selections = ModelSelectorService.new.select_multiple
        return {} if selections.empty?
      end

      PromptProcessorService.new(selections, benchmark_type).process_prompts
    end
  end
end
