# Orchestrates natural language StatBot queries against league data.
#
# Builds a system prompt, calls the LLM, parses and validates the
# response, executes SQL read-only if appropriate, and returns a
# structured result hash. Falls back from Sonnet to Haiku on LLM errors.
# Ported from fantasy-hof's LeagueQueryService.
#
# Result hash: { type: "result", messages: [<discord strings>], sql:, results_summary: }
#           or { type: "refusal" | "clarification" | "error", content: <string> }
#
# @see QuerySchemaBuilder
# @see QuerySqlValidator
# @see QueryResultFormatter
class StatsQueryService
  STATEMENT_TIMEOUT_MS = 5000
  VALID_DISPLAY_FORMATS = QueryResultFormatter::VALID_FORMATS

  class QueryError < StandardError; end

  def initialize(user:, question:, conversation:, llm_adapter: nil)
    @user = user
    @question = question
    @conversation = conversation
    @llm_adapter = llm_adapter || LlmAdapters.default
  end

  def call
    system_prompt = QuerySchemaBuilder.new(user: @user).system_prompt
    messages = @conversation.llm_messages + [{ role: "user", content: @question }]

    raw_response = call_llm(system_prompt: system_prompt, messages: messages)
    parsed = parse_response(raw_response)
    result = process_parsed_response(parsed)

    persist_conversation(result)

    result
  rescue QuerySqlValidator::InvalidQueryError => e
    Rails.logger.warn("[StatsQueryService] SQL validation failed: #{e.message}")
    error_result("I couldn't answer that question. Try rephrasing it.")
  rescue QueryError => e
    Rails.logger.warn("[StatsQueryService] Query error: #{e.message}")
    error_result(e.message)
  rescue LlmAdapters::ApiError => e
    Rails.logger.error("[StatsQueryService] LLM API error: #{e.message}")
    error_result("I couldn't answer that question right now. Please try again in a moment.")
  end

  private

  def call_llm(system_prompt:, messages:, model: nil)
    @llm_adapter.chat(system_prompt: system_prompt, messages: messages, model: model)
  rescue LlmAdapters::ApiError => e
    raise if model

    Rails.logger.info("[StatsQueryService] Primary model failed, falling back: #{e.message}")
    @llm_adapter.chat(
      system_prompt: system_prompt,
      messages: messages,
      model: LlmAdapters::AnthropicAdapter::FALLBACK_MODEL
    )
  end

  def parse_response(raw)
    cleaned = clean_llm_response(raw)
    parsed = JSON.parse(cleaned)
    validate_response_shape!(parsed)
    parsed
  rescue JSON::ParserError
    Rails.logger.warn("[StatsQueryService] Failed to parse LLM response: #{raw.truncate(500)}")
    raise QueryError, "I couldn't understand the response. Try rephrasing your question."
  end

  def clean_llm_response(text)
    cleaned = text.strip
    # Remove markdown code fences (may appear after preamble text)
    if cleaned.include?("```")
      cleaned = cleaned.sub(/\A.*?```\w*\s*\n?/m, "").sub(/\n?```\s*\z/, "")
    end
    # Strip any preamble text before the first JSON brace
    cleaned = cleaned.sub(/\A[^{]*(?=\{)/m, "") if cleaned.include?("{")
    # Collapse newlines — LLMs often produce multi-line SQL inside JSON string
    # values, which creates invalid JSON (unescaped newlines in strings)
    cleaned.gsub(/\n\s*/, " ")
  end

  def validate_response_shape!(parsed)
    return if valid_shape?(parsed)

    raise QueryError, "I can only answer questions about our league's fantasy football data."
  end

  def valid_shape?(parsed)
    parsed.is_a?(Hash) && (
      parsed.key?("refusal") ||
      parsed.key?("clarification") ||
      (parsed.key?("sql") && parsed.key?("display_format"))
    )
  end

  def process_parsed_response(parsed)
    if parsed["refusal"]
      { type: "refusal", content: parsed["refusal"].to_s }
    elsif parsed["clarification"]
      { type: "clarification", content: parsed["clarification"].to_s }
    else
      execute_query(parsed)
    end
  end

  def execute_query(parsed)
    sql = parsed["sql"].to_s
    display_format = parsed["display_format"]
    column_labels = parsed["column_labels"] || []
    headline = parsed["headline"]

    raise QueryError, "Query too complex. Try a simpler question." if sql.length > QuerySqlValidator::MAX_SQL_LENGTH

    QuerySqlValidator.validate!(sql)
    display_format = "list" unless VALID_DISPLAY_FORMATS.include?(display_format)

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    rows = execute_readonly_sql(sql)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

    log_query(sql: sql, rows_count: rows.size, duration_ms: duration_ms)

    messages = QueryResultFormatter.format(
      rows: rows, display_format: display_format, column_labels: column_labels, headline: headline
    )

    {
      type: "result",
      messages: messages,
      sql: sql,
      results_summary: "#{rows.size} row(s) returned"
    }
  rescue ActiveRecord::StatementInvalid => e
    handle_statement_error(e)
  end

  def handle_statement_error(error)
    if error.message.include?("statement timeout")
      raise QueryError, "That question was too complex to answer quickly. Try simplifying it."
    end

    Rails.logger.error("[StatsQueryService] SQL execution error: #{error.message}")
    raise QueryError, "I couldn't answer that question. Try rephrasing it."
  end

  def execute_readonly_sql(sql)
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET LOCAL statement_timeout = '#{STATEMENT_TIMEOUT_MS}'")
      ActiveRecord::Base.connection.execute("SET TRANSACTION READ ONLY")
      ActiveRecord::Base.connection.exec_query(sql).to_a
    end
  rescue PG::ReadOnlySqlTransaction => e
    Rails.logger.warn("[StatsQueryService] Read-only violation: #{e.message}")
    raise QueryError, "I couldn't answer that question. Try rephrasing it."
  end

  def persist_conversation(result)
    content = result[:type] == "result" ? result[:messages].join("\n") : result[:content]
    @conversation.append_message(role: "user", content: @question)
    @conversation.append_message(
      role: "assistant",
      content: content,
      sql: result[:sql],
      results_summary: result[:results_summary]
    )
  end

  def log_query(sql:, rows_count:, duration_ms:)
    Rails.logger.info(
      "[StatsQuery] user_id=#{@user.id} " \
      "question=#{@question.truncate(100)} sql=#{sql.truncate(200)} " \
      "rows=#{rows_count} duration_ms=#{duration_ms}"
    )
  end

  def error_result(message)
    { type: "error", content: message }
  end
end
