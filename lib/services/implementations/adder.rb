require_relative 'model_selector_service'
require_relative 'prompt_processor_service'
require_relative 'code_saver_service'

module Implementations
  class Adder
    def add
      model_id = ModelSelectorService.new.select
      PromptProcessorService.new(model_id).process_prompts
    end
  end
end
