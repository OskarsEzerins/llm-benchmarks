module Implementations
  class CodeSaverService
    def initialize(model_id)
      @model_id = model_id
    end

    def save_code(benchmark_id, content)
      create_implementation_dir(benchmark_id)
      file_name = generate_file_name(benchmark_id)

      File.write(file_name, content)
      puts "\nSaved code to: #{file_name}"
    end

    private

    def create_implementation_dir(benchmark_id)
      dir = implementations_dir(benchmark_id)
      FileUtils.mkdir_p(dir)
    end

    def implementations_dir(benchmark_id)
      File.join('implementations', benchmark_id)
    end

    def generate_file_name(benchmark_id)
      timestamp = Time.now.strftime('%m_%Y')
      File.join(implementations_dir(benchmark_id), "#{model_name}_openrouter_#{timestamp}.rb".squeeze('_'))
    end

    def model_name
      name = if ['deepseek'].any? { |provider| @model_id.include?(provider) }
               RubyLLM.models.find(@model_id).name.split(":").last.strip.tr('-.:() ', '_').downcase
             else
               @model_id.split('/').last.tr('-.:() ', '_').downcase
             end

      @model_id.include?('openai') ? name.tr('gpt', 'openai') : name
    end
  end
end
