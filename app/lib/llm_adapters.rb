module LlmAdapters
  class ApiError < StandardError; end
  class RateLimitError < ApiError; end
  class OverloadedError < ApiError; end

  def self.default
    AnthropicAdapter.new
  end
end
