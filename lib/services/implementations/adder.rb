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

      selections = ModelSelectorService.new.select_multiple
      return {} if selections.empty?

      PromptProcessorService.new(selections, benchmark_type).process_prompts
    end
  end
end
