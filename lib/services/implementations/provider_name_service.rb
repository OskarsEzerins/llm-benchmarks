# frozen_string_literal: true

require 'net/http'
require 'json'

module Implementations
  class ProviderNameService
    PROVIDERS_URL = 'https://openrouter.ai/api/v1/providers'

    def self.display_name(provider_slug)
      instance.lookup(provider_slug.to_s)
    end

    def self.instance
      @instance ||= new
    end

    def initialize
      @providers = fetch_providers
    end

    def lookup(slug)
      name = @providers[slug.downcase] || slug.split(/[-_]/).map(&:capitalize).join
      normalize(name)
    end

    private

    def normalize(name)
      case name
      when 'Google AI Studio', 'Google Vertex' then 'Google'
      when 'Amazon Nova', 'Amazon Bedrock'     then 'Amazon'
      else name
      end
    end

    def fetch_providers
      api_key = ENV.fetch('OPENROUTER_API_KEY', nil)
      return {} unless api_key

      uri = URI(PROVIDERS_URL)
      req = Net::HTTP::Get.new(uri)
      req['Authorization'] = "Bearer #{api_key}"
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
      JSON.parse(response.body).fetch('data', []).to_h { |p| [p['slug'], p['name']] }
    rescue StandardError
      {}
    end
  end
end
