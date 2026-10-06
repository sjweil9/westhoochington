# Formats raw SQL result rows into Discord embed payloads.
#
# Adapted from fantasy-hof's QueryResultFormatter for Discord as the output
# surface. Produces plain hashes ({ title:, description: }) that the Stats
# command renders as Discord embeds — nickname resolution for user id
# columns, bolded markdown lists, monospace code-block tables with a rank
# column, a hard row cap, and chunking under Discord's embed description
# limit (4096 chars).
#
# Usage:
#   QueryResultFormatter.format(
#     rows: [{ "score" => 198.5, "user_id" => 3, "season_year" => 2019, "week" => 12 }],
#     display_format: "list",
#     column_labels: ["Score", "Manager", "Year", "Week"],
#     headline: "Top single-week scores in league history"
#   )
#   # => [{ title: "Top single-week scores in league history",
#   #       description: "1. **198.5** — Hooch — 2019 — 12" }]
class QueryResultFormatter
  VALID_FORMATS = %w[scalar list table].freeze
  MAX_ROWS = 25
  MAX_DESCRIPTION_LENGTH = 3800 # headroom under Discord's 4096 embed cap
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

  # @return [Array<Hash>] embed payloads: { title: String|nil, description: String }
  def format
    return [{ title: @headline, description: EMPTY_MESSAGE }] if @rows.empty?

    case @display_format
    when "scalar" then format_scalar
    when "list" then format_list
    when "table" then format_table
    end
  end

  private

  def format_scalar
    values = @rows.first.map { |key, value| display_value(key, value) }
    description = "**#{values.first}**"
    description += "\n#{values[1..].join(' — ')}" if values.size > 1

    [{ title: @headline || effective_labels.first, description: description }]
  end

  def format_list
    lines = @rows.each_with_index.map do |row, index|
      values = row.map { |key, value| display_value(key, value) }
      line = "#{index + 1}. **#{values.first}**"
      line += " — #{values[1..].join(' — ')}" if values.size > 1
      line
    end
    lines << "_#{truncation_note}_" if truncation_note

    as_embeds(chunk_lines(lines))
  end

  def format_table
    keys = @rows.first.keys
    labels = ["#", *effective_labels.first(keys.size).map(&:to_s)]
    display_rows = @rows.each_with_index.map do |row, index|
      [(index + 1).to_s, *row.map { |key, value| display_value(key, value) }]
    end

    widths = labels.each_index.map do |i|
      [labels[i].length, *display_rows.map { |r| r[i].to_s.length }].max
    end
    numeric = [true, *keys.each_index.map do |i|
      !keys[i].to_s.match?(USER_ID_KEY) &&
        @rows.all? { |row| row.values[i].nil? || row.values[i].is_a?(Numeric) }
    end]

    header = format_table_row(labels, widths, numeric)
    separator = widths.map { |w| "-" * w }.join("-+-")
    body = display_rows.map { |row| format_table_row(row, widths, numeric) }

    descriptions = chunk_lines(body, code_block: true, header_lines: [header, separator])
    descriptions[-1] += "\n_#{truncation_note}_" if truncation_note

    as_embeds(descriptions)
  end

  def format_table_row(values, widths, numeric)
    values.each_with_index.map do |value, i|
      numeric[i] ? value.to_s.rjust(widths[i]) : value.to_s.ljust(widths[i])
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

  # The headline becomes the first embed's title; continuation chunks are
  # untitled so they read as one answer.
  def as_embeds(descriptions)
    descriptions.each_with_index.map do |description, index|
      { title: index.zero? ? @headline : nil, description: description }
    end
  end

  # Splits lines into embed-description-sized strings. With code_block, each
  # chunk is fenced and repeats the header lines so every chunk stands alone.
  def chunk_lines(lines, code_block: false, header_lines: [])
    base_length = code_block ? header_lines.sum { |l| l.length + 1 } + 8 : 0

    chunks = []
    current = []
    current_length = base_length

    lines.each do |line|
      if current.any? && current_length + line.length + 1 > MAX_DESCRIPTION_LENGTH
        chunks << finalize_chunk(current, code_block, header_lines)
        current = []
        current_length = base_length
      end
      current << line
      current_length += line.length + 1
    end

    chunks << finalize_chunk(current, code_block, header_lines) if current.any?
    chunks
  end

  def finalize_chunk(lines, code_block, header_lines)
    return lines.join("\n") unless code_block

    "```\n#{(header_lines + lines).join("\n")}\n```"
  end
end
