require 'test_helper'

class QueryResultFormatterTest < ActiveSupport::TestCase
  setup do
    @user = User.new(email: "formatter-test@example.com", password: "password123")
    @user.save!(validate: false)
    @user.nicknames.destroy_all
    @nickname = Nickname.new(name: "The Hooch", user: @user)
    @nickname.save!(validate: false)
  end

  test "formats a scalar with the headline as title and a bold value" do
    payloads = QueryResultFormatter.format(
      rows: [{ "total" => 3 }],
      display_format: "scalar",
      column_labels: ["Championships"],
      headline: "Championships won"
    )

    assert_equal [{ title: "Championships won", description: "**3**" }], payloads
  end

  test "scalar renders extra columns as a context line" do
    payloads = QueryResultFormatter.format(
      rows: [{ "score" => BigDecimal("212.44"), "user_id" => @user.id, "season_year" => 2019 }],
      display_format: "scalar",
      column_labels: %w[Score Manager Year],
      headline: "Highest score ever"
    )

    assert_equal "**212.44**\nThe Hooch — 2019", payloads.first[:description]
  end

  test "formats a list with numbering, bold primary value, nickname resolution, and rounding" do
    rows = [
      { "score" => BigDecimal("198.456"), "user_id" => @user.id },
      { "score" => BigDecimal("190.1"), "user_id" => @user.id }
    ]

    payloads = QueryResultFormatter.format(
      rows: rows,
      display_format: "list",
      column_labels: %w[Score Manager],
      headline: "Top scores"
    )

    assert_equal 1, payloads.size
    assert_equal "Top scores", payloads.first[:title]
    lines = payloads.first[:description].split("\n")
    assert_equal "1. **198.46** — The Hooch", lines[0]
    assert_equal "2. **190.1** — The Hooch", lines[1]
  end

  test "formats a table as a code block with headers and a rank column" do
    rows = [
      { "user_id" => @user.id, "wins" => 10, "losses" => 3 },
      { "user_id" => @user.id, "wins" => 8, "losses" => 5 }
    ]

    payloads = QueryResultFormatter.format(
      rows: rows,
      display_format: "table",
      column_labels: %w[Manager Wins Losses],
      headline: "Standings"
    )

    assert_equal 1, payloads.size
    assert_equal "Standings", payloads.first[:title]
    description = payloads.first[:description]
    assert description.start_with?("```\n")
    assert description.end_with?("\n```")
    assert_match(/# \| Manager\s+\|\s+Wins \| Losses/, description)
    assert_match(/1 \| The Hooch/, description)
  end

  test "caps rows and appends a truncation note" do
    rows = (1..40).map { |i| { "score" => i } }

    payloads = QueryResultFormatter.format(
      rows: rows,
      display_format: "list",
      column_labels: ["Score"]
    )

    text = payloads.map { |p| p[:description] }.join("\n")
    assert_match(/25\./, text)
    assert_no_match(/26\./, text)
    assert_match(/plus 15 more/, text)
  end

  test "splits long output into multiple embeds under the description limit" do
    rows = (1..25).map { |i| { "note" => "x" * 300, "score" => i } }

    payloads = QueryResultFormatter.format(
      rows: rows,
      display_format: "list",
      column_labels: %w[Note Score],
      headline: "Long notes"
    )

    assert_operator payloads.size, :>, 1
    assert_equal "Long notes", payloads.first[:title]
    assert_nil payloads.last[:title]
    payloads.each { |p| assert_operator p[:description].length, :<=, 4096 }
  end

  test "repeats the table header in every chunk" do
    rows = (1..25).map { |i| { "note" => "y" * 300, "score" => i } }

    payloads = QueryResultFormatter.format(
      rows: rows,
      display_format: "table",
      column_labels: %w[Note Score]
    )

    assert_operator payloads.size, :>, 1
    payloads.each do |p|
      assert p[:description].start_with?("```\n"), "chunk should open a code block"
      assert_match(/Note/, p[:description])
      assert_operator p[:description].length, :<=, 4096
    end
  end

  test "returns a friendly payload for empty results" do
    payloads = QueryResultFormatter.format(
      rows: [],
      display_format: "table",
      column_labels: [],
      headline: "Top scores"
    )

    assert_equal [{ title: "Top scores", description: QueryResultFormatter::EMPTY_MESSAGE }], payloads
  end

  test "falls back to list for unknown display formats" do
    payloads = QueryResultFormatter.format(
      rows: [{ "score" => 1 }],
      display_format: "hologram",
      column_labels: ["Score"]
    )

    assert_equal "1. **1**", payloads.first[:description]
  end
end
