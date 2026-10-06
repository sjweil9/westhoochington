require "net/http"

module LlmAdapters
  # Calls the Anthropic Messages API directly via Net::HTTP.
  #
  # Mirrors fantasy-hof's AnthropicAdapter interface; the official
  # `anthropic` gem requires Ruby >= 3.2, which this app does not run.
  class AnthropicAdapter < BaseAdapter
    API_HOST = "api.anthropic.com".freeze
    API_PATH = "/v1/messages".freeze
    ANTHROPIC_VERSION = "2023-06-01".freeze
    DEFAULT_MODEL = "claude-sonnet-4-6".freeze
    FALLBACK_MODEL = "claude-haiku-4-5-20251001".freeze
    MAX_TOKENS = 2048
    OPEN_TIMEOUT = 10
    REQUEST_TIMEOUT = 45

    def chat(system_prompt:, messages:, model: nil)
      model ||= DEFAULT_MODEL
      body = {
        model: model,
        max_tokens: MAX_TOKENS,
        system: [
          {
            type: "text",
            text: system_prompt,
            cache_control: { type: "ephemeral" }
          }
        ],
        messages: messages
      }

      handle_response(post_request(body))
    end

    private

    def post_request(body)
      http = Net::HTTP.new(API_HOST, 443)
      http.use_ssl = true
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = REQUEST_TIMEOUT
      http.write_timeout = REQUEST_TIMEOUT if http.respond_to?(:write_timeout=)

      request = Net::HTTP::Post.new(API_PATH)
      request["content-type"] = "application/json"
      request["x-api-key"] = api_key
      request["anthropic-version"] = ANTHROPIC_VERSION
      request.body = body.to_json

      http.request(request)
    rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Timeout::Error,
           SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EPIPE,
           OpenSSL::SSL::SSLError, EOFError => e
      raise LlmAdapters::ApiError, "Anthropic connection error: #{e.class}: #{e.message}"
    end

    def handle_response(response)
      status = response.code.to_i

      case status
      when 200
        extract_text(response.body)
      when 429
        raise LlmAdapters::RateLimitError, "Anthropic rate limit (status 429)"
      when 529
        raise LlmAdapters::OverloadedError, "Anthropic overloaded (status 529)"
      else
        raise LlmAdapters::ApiError, "Anthropic API error (status #{status}): #{error_message(response.body)}"
      end
    end

    def extract_text(body)
      parsed = JSON.parse(body)
      text = parsed.dig("content", 0, "text")
      raise LlmAdapters::ApiError, "Anthropic response contained no text content" if text.blank?

      text
    rescue JSON::ParserError
      raise LlmAdapters::ApiError, "Anthropic response was not valid JSON"
    end

    def error_message(body)
      JSON.parse(body).dig("error", "message").to_s.truncate(200)
    rescue JSON::ParserError, TypeError
      ""
    end

    def api_key
      ENV["ANTHROPIC_API_KEY"].presence ||
        credentials_api_key ||
        raise("Anthropic API key not configured. Set ANTHROPIC_API_KEY or credentials.anthropic.api_key.")
    end

    # Credentials may be undecryptable on a given machine (missing or
    # mismatched master key); that must never break ENV-based configuration.
    def credentials_api_key
      Rails.application.credentials.dig(:anthropic, :api_key).presence
    rescue ActiveSupport::EncryptedFile::MissingKeyError, OpenSSL::Cipher::CipherError,
           ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end
  end
end
