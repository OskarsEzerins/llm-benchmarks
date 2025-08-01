require_relative 'model_selector_service'
require_relative 'prompt_processor_service'
require_relative 'code_saver_service'
require_relative 'benchmark_type_selector_service'

module Implementations
  class Adder
    def add
      benchmark_type = BenchmarkTypeSelectorService.new.select
      return puts 'No benchmark type selected.' unless benchmark_type

      model_id = ModelSelectorService.new.select
      return puts 'No model selected.' unless model_id

      PromptProcessorService.new(model_id, benchmark_type).process_prompts
    end
  end
end
