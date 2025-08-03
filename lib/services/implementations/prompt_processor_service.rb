require_relative '../../../config'

module Implementations
  class PromptProcessorService
    def initialize(model_ids, benchmark_type = :all_types)
      @model_ids = Array(model_ids)
      @benchmark_type = benchmark_type
    end

    def process_prompts
      target_benchmarks = self.target_benchmarks
      return display_no_benchmarks_message if target_benchmarks.empty?

      display_processing_summary(target_benchmarks)
      process_models_and_benchmarks(target_benchmarks)
    end

    private

    def display_no_benchmarks_message
      puts "No benchmarks found for type: #{@benchmark_type}"
    end

    def display_processing_summary(target_benchmarks)
      puts "Processing #{target_benchmarks.size} benchmark(s) for type: #{@benchmark_type}"
      puts "Using #{@model_ids.size} model(s): #{@model_ids.join(', ')}"
    end

    def process_models_and_benchmarks(target_benchmarks)
      @model_ids.each do |model_id|
        display_model_header(model_id)
        process_benchmarks_for_model(model_id, target_benchmarks)
      end
    end

    def display_model_header(model_id)
      puts "\n#{'=' * 50}"
      puts "Processing with model: #{model_id}"
      puts "=" * 50
    end

    def process_benchmarks_for_model(model_id, target_benchmarks)
      code_saver = CodeSaverService.new(model_id)

      target_benchmarks.each do |benchmark_id|
        next unless validate_prompt_file(benchmark_id)
        next if skip_existing_implementation?(code_saver, model_id, benchmark_id)

        process_single_benchmark(model_id, benchmark_id, code_saver)
      end
    end

    def validate_prompt_file(benchmark_id)
      prompt_file = Config.benchmark_prompt(benchmark_id)
      return true if File.exist?(prompt_file)

      puts "Warning: Prompt file not found for #{benchmark_id}"
      false
    end

    def skip_existing_implementation?(code_saver, model_id, benchmark_id)
      return false unless code_saver.send(:implementation_exists?, benchmark_id)

      puts "Skipping #{model_id} for #{benchmark_id} - implementation already exists for this month"
      true
    end

    def process_single_benchmark(model_id, benchmark_id, code_saver)
      prompt_file = Config.benchmark_prompt(benchmark_id)
      puts "
Processing prompt from: #{prompt_file}"

      prompt_content = File.read(prompt_file)
      response = RubyLLM.chat(model: model_id).ask(prompt_content)
      content = extract_ruby_code(response.content)

      code_saver.save_code(benchmark_id, content)
    end

    def target_benchmarks
      case @benchmark_type
      when :performance
        Config.benchmarks_by_type(:performance)
      when :program_fixer
        Config.benchmarks_by_type(:program_fixer)
      else # :all_types or any other value
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
