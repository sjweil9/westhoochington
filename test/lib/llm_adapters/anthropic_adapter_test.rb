require 'test_helper'

class AnthropicAdapterTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:code, :body)

  setup do
    @adapter = LlmAdapters::AnthropicAdapter.new
  end

  test "extracts text from a successful response" do
    body = { content: [{ type: "text", text: '{"sql": "SELECT 1"}' }] }.to_json

    assert_equal '{"sql": "SELECT 1"}', @adapter.send(:handle_response, FakeResponse.new("200", body))
  end

  test "raises RateLimitError on 429" do
    assert_raises(LlmAdapters::RateLimitError) do
      @adapter.send(:handle_response, FakeResponse.new("429", "{}"))
    end
  end

  test "raises OverloadedError on 529" do
    assert_raises(LlmAdapters::OverloadedError) do
      @adapter.send(:handle_response, FakeResponse.new("529", "{}"))
    end
  end

  test "raises ApiError on other statuses with the api message" do
    body = { error: { message: "invalid request" } }.to_json
    error = assert_raises(LlmAdapters::ApiError) do
      @adapter.send(:handle_response, FakeResponse.new("400", body))
    end

    assert_match(/status 400/, error.message)
    assert_match(/invalid request/, error.message)
  end

  test "raises ApiError when the response has no text content" do
    body = { content: [] }.to_json

    assert_raises(LlmAdapters::ApiError) do
      @adapter.send(:handle_response, FakeResponse.new("200", body))
    end
  end

  test "raises ApiError on unparseable success bodies" do
    assert_raises(LlmAdapters::ApiError) do
      @adapter.send(:handle_response, FakeResponse.new("200", "not json"))
    end
  end

  test "api_key prefers ENV over credentials and tolerates undecryptable credentials" do
    original = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "env-test-key"

    assert_equal "env-test-key", @adapter.send(:api_key)
  ensure
    ENV["ANTHROPIC_API_KEY"] = original
  end
end
