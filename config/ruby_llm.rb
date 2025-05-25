require 'ruby_llm'

RubyLLM.configure do |config|
  config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY", nil)
end
