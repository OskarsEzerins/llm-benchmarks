require_relative '../../../config'

module Implementations
  class PromptProcessorService
    def initialize(model_ids, benchmark_type = :all_types)
      @model_ids = Array(model_ids)
      @benchmark_type = benchmark_type
    end

    def process_prompts
      target_benchmarks = get_target_benchmarks

      if target_benchmarks.empty?
        puts "No benchmarks found for type: #{@benchmark_type}"
        return
      end

      puts "Processing #{target_benchmarks.size} benchmark(s) for type: #{@benchmark_type}"
      puts "Using #{@model_ids.size} model(s): #{@model_ids.join(', ')}"

      @model_ids.each do |model_id|
        puts "\n#{'=' * 50}"
        puts "Processing with model: #{model_id}"
        puts "=" * 50

        target_benchmarks.each do |benchmark_id|
          prompt_file = Config.benchmark_prompt(benchmark_id)

          unless File.exist?(prompt_file)
            puts "Warning: Prompt file not found for #{benchmark_id}"
            next
          end

          code_saver = CodeSaverService.new(model_id)

          # Check if implementation already exists for this model and month
          if code_saver.send(:implementation_exists?, benchmark_id)
            puts "Skipping #{model_id} for #{benchmark_id} - implementation already exists for this month"
            next
          end

          puts "\nProcessing prompt from: #{prompt_file}"
          prompt_content = File.read(prompt_file)

          # For ProgramFixer benchmarks, append test suite content if available
          # prompt_content = append_test_content_if_program_fixer(prompt_content, benchmark_id)

          response = RubyLLM.chat(model: model_id).ask(prompt_content)
          content = extract_ruby_code(response.content)

          code_saver.save_code(benchmark_id, content)
        end
      end
    end

    private

    def get_target_benchmarks
      case @benchmark_type
      when :all_types
        Config.benchmarks
      when :performance
        Config.benchmarks_by_type(:performance)
      when :program_fixer
        Config.benchmarks_by_type(:program_fixer)
      else
        Config.benchmarks
      end
    end

    def append_test_content_if_program_fixer(prompt_content, benchmark_id)
      benchmark_config = Config.benchmark_config(benchmark_id)
      return prompt_content unless benchmark_config[:type] == :program_fixer

      test_suite_file = "#{Config.benchmark_file(benchmark_id)}.test_suite.rb"
      return prompt_content unless File.exist?(test_suite_file)

      test_content = File.read(test_suite_file)

      "#{prompt_content}\n\n" \
        "#{'=' * 50}\n" \
        "TEST SUITE (test_suite.rb):\n" \
        "#{'=' * 50}\n\n" \
        "#{test_content}"
    end

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
