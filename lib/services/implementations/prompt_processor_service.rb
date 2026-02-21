require_relative '../../../config'

module Implementations
  class PromptProcessorService
    def initialize(model_ids, benchmark_type = :all_types)
      @model_ids = Array(model_ids)
      @benchmark_type = benchmark_type
    end

    # Returns a hash of { benchmark_id => [slug, ...] } for newly saved implementations
    def process_prompts
      target_benchmarks = self.target_benchmarks
      if target_benchmarks.empty?
        puts "No benchmarks found for type: #{@benchmark_type}"
        return {}
      end

      puts "Processing #{target_benchmarks.size} benchmark(s) for type: #{@benchmark_type}"
      puts "Using #{@model_ids.size} model(s): #{@model_ids.join(', ')}"
      process_models_and_benchmarks(target_benchmarks)
    end

    private

    def process_models_and_benchmarks(target_benchmarks)
      added = Hash.new { |h, k| h[k] = [] }
      @model_ids.each do |model_id|
        puts "\n#{'=' * 50}"
        puts "Processing with model: #{model_id}"
        puts "=" * 50
        process_benchmarks_for_model(model_id, target_benchmarks, added)
      end
      added
    end

    def process_benchmarks_for_model(model_id, target_benchmarks, added)
      code_saver = CodeSaverService.new(model_id)

      target_benchmarks.each do |benchmark_id|
        next unless validate_prompt_file(benchmark_id)
        next if skip_existing_implementation?(code_saver, model_id, benchmark_id)

        slug = process_single_benchmark(model_id, benchmark_id, code_saver)
        added[benchmark_id] << slug if slug
      end
    end

    def validate_prompt_file(benchmark_id)
      prompt_file = Config.benchmark_prompt(benchmark_id)
      return true if File.exist?(prompt_file)

      puts "Warning: Prompt file not found for #{benchmark_id}"
      false
    end

    def skip_existing_implementation?(code_saver, model_id, benchmark_id)
      return false unless code_saver.implementation_exists?(benchmark_id)

      puts "Skipping #{model_id} for #{benchmark_id} - implementation already exists for this month"
      true
    end

    def process_single_benchmark(model_id, benchmark_id, code_saver)
      prompt_file = Config.benchmark_prompt(benchmark_id)
      puts "\nProcessing prompt from: #{prompt_file}"

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

    def extract_ruby_code(response)
      if response.include?('```ruby')
        response.split('```ruby').last.split('```').first.strip
      else
        response.strip
      end
    end
  end
end
