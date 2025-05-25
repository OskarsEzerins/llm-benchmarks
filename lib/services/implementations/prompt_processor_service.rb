module Implementations
  class PromptProcessorService
    def initialize(model_id)
      @model_id = model_id
    end

    def process_prompts
      Dir.glob(File.join('benchmarks', '*', 'prompt')).each do |prompt_file|
        next if prompt_file.include?('template')

        benchmark_id = extract_benchmark_id(prompt_file)
        puts "\nProcessing prompt from: #{prompt_file}"
        prompt_content = File.read(prompt_file)

        response = RubyLLM.chat(model: @model_id).ask(prompt_content)
        content = extract_ruby_code(response.content)

        CodeSaverService.new(@model_id).save_code(benchmark_id, content)
      end
    end

    private

    def extract_ruby_code(response)
      if response.include?('```ruby')
        response.split('```ruby').last.split('```').first.strip
      else
        response.strip
      end
    end

    def extract_benchmark_id(prompt_file)
      prompt_file.split(File::SEPARATOR)[1]
    end
  end
end
