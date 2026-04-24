require 'json'
require 'fileutils'
require_relative 'provider_name_service'
require_relative 'display_name_normalizer_service'
require_relative 'model_variant_registry'

module Implementations
  class CodeSaverService
    MODEL_NAMES_CONFIG = File.expand_path('../../../config/model_names.json', __dir__)

    def initialize(selection)
      @metadata = if selection.is_a?(Hash)
                    selection
                  else
                    ModelVariantRegistry.instance.metadata_for_raw_model(selection)
                  end
      @model_id = @metadata['model_id']
    end

    def save_code(benchmark_id, content)
      create_implementation_dir(benchmark_id)
      file_name = generate_file_name(benchmark_id)

      if implementation_exists?(benchmark_id)
        puts "\nSkipping #{model_display_name} for #{benchmark_id} - implementation already exists for this month"
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

    attr_reader :metadata

    def create_implementation_dir(benchmark_id)
      dir = implementations_dir(benchmark_id)
      FileUtils.mkdir_p(dir)
    end

    def implementations_dir(benchmark_id)
      Config.implementations_dir(benchmark_id)
    end

    def generate_file_name(benchmark_id)
      timestamp = Time.now.strftime('%m_%Y')
      File.join(
        implementations_dir(benchmark_id),
        "#{implementation_slug_prefix}_#{source_tag}_#{timestamp}.rb".squeeze('_')
      )
    end

    def model_info
      @model_info ||= RubyLLM.models.find(@model_id)
    rescue StandardError
      nil
    end

    def implementation_slug_prefix
      metadata['implementation_slug_prefix'] || model_name
    end

    def source_tag
      metadata['source_tag'] || 'openrouter'
    end

    def model_name
      return metadata['implementation_slug_prefix'] if metadata['implementation_slug_prefix']

      name = if @model_id.include?('deepseek')
               model_info.name.split(':').last.strip.tr('-.:() ', '_').downcase
             else
               @model_id.split('/').last.tr('-.:() ', '_').downcase
             end

      @model_id.include?('openai') ? "openai_#{name.gsub('gpt', '')}" : name
    end

    def model_display_name
      return metadata['display_name'] if metadata['display_name']

      raw_name = model_info&.name || @model_id.split('/').last
      DisplayNameNormalizerService.normalize(
        model_id: @model_id,
        raw_name: raw_name,
        provider: model_provider
      )
    rescue StandardError
      @model_id.split('/').last
    end

    def model_provider
      return metadata['provider'] if metadata['provider']

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
