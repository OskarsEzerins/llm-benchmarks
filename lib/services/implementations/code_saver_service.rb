require 'json'
require_relative 'provider_name_service'

module Implementations
  class CodeSaverService
    MODEL_NAMES_CONFIG = File.expand_path('../../../config/model_names.json', __dir__)

    def initialize(model_id)
      @model_id = model_id
    end

    def save_code(benchmark_id, content)
      create_implementation_dir(benchmark_id)
      file_name = generate_file_name(benchmark_id)

      if implementation_exists?(benchmark_id)
        puts "\nSkipping #{@model_id} for #{benchmark_id} - implementation already exists for this month"
        return nil
      end

      File.write(file_name, content)
      slug = File.basename(file_name, '.rb')
      puts "\nSaved code to: #{file_name}"
      update_model_names_config(slug)
      slug
    end

    def implementation_exists?(benchmark_id)
      file_name = generate_file_name(benchmark_id)
      File.exist?(file_name)
    end

    private

    def create_implementation_dir(benchmark_id)
      dir = implementations_dir(benchmark_id)
      FileUtils.mkdir_p(dir)
    end

    def implementations_dir(benchmark_id)
      Config.implementations_dir(benchmark_id)
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

      @model_id.include?('openai') ? "openai_#{name.gsub('gpt', '')}" : name
    end

    def model_display_name
      model_info = RubyLLM.models.find(@model_id)
      name = model_info&.name || @model_id.split('/').last
      # Strip "Provider: " prefix that some ruby_llm model names include (e.g. "Qwen: Qwen3 Coder Next")
      name.include?(': ') ? name.split(': ', 2).last : name
    rescue StandardError
      @model_id.split('/').last
    end

    def model_provider
      model_info = RubyLLM.models.find(@model_id)
      return 'Other' unless model_info

      provider_slug = if model_info.provider == 'openrouter'
                        @model_id.split('/').first
                      else
                        model_info.provider
                      end

      ProviderNameService.display_name(provider_slug)
    rescue StandardError
      'Other'
    end

    def update_model_names_config(slug)
      config = File.exist?(MODEL_NAMES_CONFIG) ? JSON.parse(File.read(MODEL_NAMES_CONFIG)) : {}
      return if config.key?(slug)

      config[slug] = { 'display_name' => model_display_name, 'provider' => model_provider }
      sorted = config.sort.to_h
      File.write(MODEL_NAMES_CONFIG, JSON.pretty_generate(sorted))
      puts "Updated model_names.json: #{slug} => #{config[slug]}"
    rescue StandardError => e
      puts "Warning: could not update model_names.json: #{e.message}"
    end
  end
end
