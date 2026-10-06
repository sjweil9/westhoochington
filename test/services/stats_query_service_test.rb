require 'test_helper'

class StatsQueryServiceTest < ActiveSupport::TestCase
  class StubAdapter < LlmAdapters::BaseAdapter
    attr_reader :calls

    def initialize(responses)
      @responses = Array(responses)
      @calls = []
    end

    def chat(system_prompt:, messages:, model: nil)
      @calls << { system_prompt: system_prompt, messages: messages, model: model }
      response = @responses.shift
      raise response if response.is_a?(StandardError) || (response.is_a?(Class) && response < StandardError)

      response
    end
  end

  setup do
    @user = User.new(email: "stats-service-test@example.com", password: "password123")
    @user.save!(validate: false)
    @conversation = QueryConversationStore::Conversation.new
  end


  def service_with(responses)
    StatsQueryService.new(
      user: @user,
      question: "How many finished games are recorded?",
      conversation: @conversation,
      llm_adapter: StubAdapter.new(responses)
    )
  end

  test "executes validated sql and returns formatted discord messages" do
    response = {
      sql: "SELECT COUNT(*) AS total FROM games WHERE finished = true",
      display_format: "scalar",
      column_labels: ["Finished games"],
      headline: "Finished games on record"
    }.to_json

    result = service_with(response).call

    assert_equal "result", result[:type]
    assert_equal 1, result[:messages].size
    assert_match(/Finished games on record: \*\*\d+\*\*/, result[:messages].first)
    assert_equal "1 row(s) returned", result[:results_summary]
  end

  test "persists the exchange to the conversation" do
    response = {
      sql: "SELECT COUNT(*) AS total FROM games",
      display_format: "scalar",
      column_labels: ["Games"]
    }.to_json

    service_with(response).call

    roles = @conversation.llm_messages.map { |m| m[:role] }
    assert_equal %w[user assistant], roles
  end

  test "relays refusals" do
    result = service_with({ refusal: "I only answer league questions." }.to_json).call

    assert_equal "refusal", result[:type]
    assert_equal "I only answer league questions.", result[:content]
  end

  test "relays clarifications" do
    result = service_with({ clarification: "Which Mike do you mean?" }.to_json).call

    assert_equal "clarification", result[:type]
    assert_equal "Which Mike do you mean?", result[:content]
  end

  test "rejects responses that match no allowed shape" do
    result = service_with({ answer: "Here is a poem about football" }.to_json).call

    assert_equal "error", result[:type]
    assert_match(/league's fantasy football data/, result[:content])
  end

  test "rejects unparseable responses" do
    result = service_with("Sure! The highest score was...").call

    assert_equal "error", result[:type]
    assert_match(/rephrasing/, result[:content])
  end

  test "returns an error when generated sql fails validation" do
    response = {
      sql: "DELETE FROM games",
      display_format: "table",
      column_labels: []
    }.to_json

    result = service_with(response).call

    assert_equal "error", result[:type]
    assert_match(/rephrasing/, result[:content])
  end

  test "blocks sql referencing the users table" do
    response = {
      sql: "SELECT email FROM users LIMIT 1",
      display_format: "list",
      column_labels: ["Email"]
    }.to_json

    result = service_with(response).call

    assert_equal "error", result[:type]
  end

  test "falls back to the fallback model when the primary call fails" do
    response = {
      sql: "SELECT COUNT(*) AS total FROM games",
      display_format: "scalar",
      column_labels: ["Games"]
    }.to_json
    adapter = StubAdapter.new([LlmAdapters::ApiError.new("boom"), response])

    result = StatsQueryService.new(
      user: @user, question: "how many games?", conversation: @conversation, llm_adapter: adapter
    ).call

    assert_equal "result", result[:type]
    assert_equal 2, adapter.calls.size
    assert_nil adapter.calls.first[:model]
    assert_equal LlmAdapters::AnthropicAdapter::FALLBACK_MODEL, adapter.calls.last[:model]
  end

  test "returns a friendly error when both models fail" do
    adapter = StubAdapter.new([LlmAdapters::ApiError.new("boom"), LlmAdapters::ApiError.new("boom again")])

    result = StatsQueryService.new(
      user: @user, question: "how many games?", conversation: @conversation, llm_adapter: adapter
    ).call

    assert_equal "error", result[:type]
    assert_match(/try again/i, result[:content])
  end
end
