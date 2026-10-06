require 'test_helper'

class QueryResultFormatterTest < ActiveSupport::TestCase
  setup do
    @user = User.new(email: "formatter-test@example.com", password: "password123")
    @user.save!(validate: false)
    @user.nicknames.destroy_all
    @nickname = Nickname.new(name: "The Hooch", user: @user)
    @nickname.save!(validate: false)
  end


  test "formats a scalar with a headline" do
    messages = QueryResultFormatter.format(
      rows: [{ "total" => 3 }],
      display_format: "scalar",
      column_labels: ["Championships"],
      headline: "Championships won"
    )

    assert_equal ["Championships won: **3**"], messages
  end

  test "formats a list with numbering, nickname resolution, and rounding" do
    rows = [
      { "score" => BigDecimal("198.456"), "user_id" => @user.id, "season_year" => 2019, "week" => 12 },
      { "score" => BigDecimal("190.1"), "user_id" => @user.id, "season_year" => 2021, "week" => 3 }
    ]

    messages = QueryResultFormatter.format(
      rows: rows,
      display_format: "list",
      column_labels: %w[Score Manager Year Week],
      headline: "Top scores"
    )

    assert_equal 1, messages.size
    lines = messages.first.split("\n")
    assert_equal "Top scores", lines[0]
    assert_equal "1) 198.46 — The Hooch — 2019 — 12", lines[1]
    assert_equal "2) 190.1 — The Hooch — 2021 — 3", lines[2]
  end

  test "formats a table as a code block with headers" do
    rows = [
      { "user_id" => @user.id, "wins" => 10, "losses" => 3 },
      { "user_id" => @user.id, "wins" => 8, "losses" => 5 }
    ]

    messages = QueryResultFormatter.format(
      rows: rows,
      display_format: "table",
      column_labels: %w[Manager Wins Losses]
    )

    assert_equal 1, messages.size
    assert messages.first.start_with?("```\n")
    assert messages.first.end_with?("\n```")
    assert_match(/Manager\s+\|\s+Wins \| Losses/, messages.first)
    assert_match(/The Hooch/, messages.first)
  end

  test "caps rows and appends a truncation note" do
    rows = (1..40).map { |i| { "score" => i } }

    messages = QueryResultFormatter.format(
      rows: rows,
      display_format: "list",
      column_labels: ["Score"]
    )

    text = messages.join("\n")
    assert_match(/25\)/, text)
    assert_no_match(/26\)/, text)
    assert_match(/plus 15 more/, text)
  end

  test "splits long output into multiple messages under the discord limit" do
    rows = (1..25).map { |i| { "note" => "x" * 150, "score" => i } }

    messages = QueryResultFormatter.format(
      rows: rows,
      display_format: "list",
      column_labels: %w[Note Score]
    )

    assert_operator messages.size, :>, 1
    messages.each { |message| assert_operator message.length, :<=, 2000 }
  end

  test "repeats the table header in every chunk" do
    rows = (1..25).map { |i| { "note" => "y" * 150, "score" => i } }

    messages = QueryResultFormatter.format(
      rows: rows,
      display_format: "table",
      column_labels: %w[Note Score]
    )

    assert_operator messages.size, :>, 1
    messages.each do |message|
      assert message.start_with?("```\n"), "chunk should open a code block"
      assert_match(/Note/, message)
    end
  end

  test "returns a friendly message for empty results" do
    messages = QueryResultFormatter.format(
      rows: [],
      display_format: "table",
      column_labels: [],
      headline: "Top scores"
    )

    assert_equal ["Top scores\n#{QueryResultFormatter::EMPTY_MESSAGE}"], messages
  end

  test "falls back to list for unknown display formats" do
    messages = QueryResultFormatter.format(
      rows: [{ "score" => 1 }],
      display_format: "hologram",
      column_labels: ["Score"]
    )

    assert_equal ["1) 1"], messages
  end
end
