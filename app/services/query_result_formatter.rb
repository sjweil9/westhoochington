# Formats raw SQL result rows into Discord-ready message strings.
#
# Adapted from fantasy-hof's QueryResultFormatter for Discord as the output
# surface: nickname resolution for user id columns, numbered lists,
# monospace code-block tables, a hard row cap, and chunking under Discord's
# 2000-character message limit.
#
# Usage:
#   QueryResultFormatter.format(
#     rows: [{ "score" => 198.5, "user_id" => 3, "season_year" => 2019, "week" => 12 }],
#     display_format: "list",
#     column_labels: ["Score", "Manager", "Year", "Week"],
#     headline: "Top single-week scores in league history"
#   )
#   # => ["Top single-week scores in league history\n1) 198.5 — Hooch — 2019 — Week 12"]
class QueryResultFormatter
  VALID_FORMATS = %w[scalar list table].freeze
  MAX_ROWS = 25
  MAX_MESSAGE_LENGTH = 1900 # headroom under Discord's 2000-char limit
  EMPTY_MESSAGE = "No results found. Try rephrasing the question.".freeze

  # Columns holding a user id get resolved to that member's nickname.
  USER_ID_KEY = /(?:\A|_)(?:user|opponent|winner|loser|member|manager)_id\z/.freeze

  def self.format(rows:, display_format:, column_labels:, headline: nil)
    new(rows: rows, display_format: display_format, column_labels: column_labels, headline: headline).format
  end

  def initialize(rows:, display_format:, column_labels:, headline: nil)
    @rows = rows.first(MAX_ROWS)
    @truncated_count = rows.size - @rows.size
    @display_format = VALID_FORMATS.include?(display_format) ? display_format : "list"
    @column_labels = Array(column_labels)
    @headline = headline.to_s.strip.presence
  end

  def format
    return [[@headline, EMPTY_MESSAGE].compact.join("\n")] if @rows.empty?

    case @display_format
    when "scalar" then format_scalar
    when "list" then format_list
    when "table" then format_table
    end
  end

  private

  def format_scalar
    value = display_value(@rows.first.keys.first, @rows.first.values.first)
    label = @headline || effective_labels.first
    [label ? "#{label}: **#{value}**" : "**#{value}**"]
  end

  def format_list
    lines = @rows.each_with_index.map do |row, index|
      values = row.map { |key, value| display_value(key, value) }
      "#{index + 1}) #{values.join(' — ')}"
    end
    lines << truncation_note if truncation_note

    with_headline(chunk_plain(lines))
  end

  def format_table
    keys = @rows.first.keys
    labels = effective_labels
    display_rows = @rows.map { |row| row.map { |key, value| display_value(key, value) } }

    widths = keys.each_index.map do |i|
      [labels[i].to_s.length, *display_rows.map { |row| row[i].length }].max
    end
    numeric = keys.each_index.map do |i|
      !keys[i].to_s.match?(USER_ID_KEY) &&
        @rows.all? { |row| row.values[i].nil? || row.values[i].is_a?(Numeric) }
    end

    header = format_table_row(labels.map(&:to_s), widths, numeric)
    separator = widths.map { |w| "-" * w }.join("-+-")
    body = display_rows.map { |row| format_table_row(row, widths, numeric) }

    messages = chunk_code_block(body, header_lines: [header, separator])
    messages << truncation_note if truncation_note

    with_headline(messages)
  end

  def format_table_row(values, widths, numeric)
    values.each_with_index.map do |value, i|
      numeric[i] ? value.rjust(widths[i]) : value.ljust(widths[i])
    end.join(" | ").rstrip
  end

  def display_value(key, value)
    return nickname_for(value.to_i) if key.to_s.match?(USER_ID_KEY) && value.to_s.match?(/\A\d+\z/)

    case value
    when nil then "—"
    when BigDecimal, Float then format_number(value)
    else value.to_s
    end
  end

  def format_number(value)
    rounded = value.to_f.round(2)
    rounded == rounded.to_i ? rounded.to_i.to_s : rounded.to_s
  end

  def nickname_for(user_id)
    nicknames[user_id] ||= User.find_by(id: user_id)&.random_nickname || "User #{user_id}"
  end

  def nicknames
    @nicknames ||= {}
  end

  def effective_labels
    return @column_labels if @column_labels.any?

    @rows.first.keys.map { |key| key.to_s.humanize }
  end

  def truncation_note
    return nil unless @truncated_count.positive?

    "…plus #{@truncated_count} more — showing the first #{MAX_ROWS}."
  end

  def with_headline(messages)
    return messages unless @headline

    if messages.any? && @headline.length + 1 + messages.first.length <= MAX_MESSAGE_LENGTH
      messages[0] = "#{@headline}\n#{messages.first}"
      messages
    else
      [@headline, *messages]
    end
  end

  # Splits plain lines into messages under the Discord limit.
  def chunk_plain(lines)
    chunks = []
    current = []
    current_length = 0

    lines.each do |line|
      if current.any? && current_length + line.length + 1 > MAX_MESSAGE_LENGTH
        chunks << current.join("\n")
        current = []
        current_length = 0
      end
      current << line
      current_length += line.length + 1
    end

    chunks << current.join("\n") if current.any?
    chunks
  end

  # Splits table body lines into fenced code blocks, repeating the header in
  # each chunk so every message stands alone.
  def chunk_code_block(body_lines, header_lines:)
    fence_overhead = 8 # "```\n" + "\n```"
    base_length = header_lines.sum { |line| line.length + 1 } + fence_overhead

    chunks = []
    current = []
    current_length = base_length

    body_lines.each do |line|
      if current.any? && current_length + line.length + 1 > MAX_MESSAGE_LENGTH
        chunks << wrap_code_block(header_lines + current)
        current = []
        current_length = base_length
      end
      current << line
      current_length += line.length + 1
    end

    chunks << wrap_code_block(header_lines + current) if current.any?
    chunks
  end

  def wrap_code_block(lines)
    "```\n#{lines.join("\n")}\n```"
  end
end
