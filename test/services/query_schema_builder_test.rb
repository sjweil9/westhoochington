require 'test_helper'

class QuerySchemaBuilderTest < ActiveSupport::TestCase
  setup do
    @user = User.new(email: "schema-builder-test@example.com", password: "password123")
    @user.save!(validate: false)
    @user.nicknames.destroy_all
    Nickname.new(name: "Schema Tester", user: @user).save!(validate: false)
    @prompt = QuerySchemaBuilder.new(user: @user).system_prompt
  end


  test "includes ddl for allowlisted tables only" do
    assert_includes @prompt, "CREATE TABLE games ("
    assert_includes @prompt, "CREATE TABLE season_user_stats ("
    assert_not_includes @prompt, "CREATE TABLE users ("
    assert_not_includes @prompt, "encrypted_password"
  end

  test "includes the schema guide from docs" do
    assert_includes @prompt, "One Row Per Team Per Matchup"
    assert_includes @prompt, "Result Composition Defaults"
  end

  test "includes the member roster with nicknames and seasons played" do
    assert_includes @prompt, "## League Member Roster"
    assert_includes @prompt, "user_id #{@user.id}: \"Schema Tester\""
    assert_includes @prompt, "— seasons: none (best ball / side participant only)"
    assert_includes @prompt, "never attribute a season to a member outside"
  end

  test "roster lists seasons derived from finished games" do
    opponent = User.new(email: "schema-builder-opponent@example.com", password: "password123")
    opponent.save!(validate: false)
    [2016, 2017, 2019].each do |year|
      Game.create!(user: @user, opponent: opponent, season_year: year, week: 1, finished: true)
    end

    prompt = QuerySchemaBuilder.new(user: @user).system_prompt
    assert_match(/user_id #{@user.id}:.*— seasons: 2016–2017, 2019/, prompt)
  end

  test "identifies the asking user" do
    assert_includes @prompt, "The person asking is user_id #{@user.id}."
  end

  test "includes current date context for completed-season filtering" do
    assert_includes @prompt, "## Current Date"
    assert_includes @prompt, "The current season_year is #{Date.current.year}."
    assert_includes @prompt, "season_year < #{Date.current.year}"
  end

  test "includes constraints and response format" do
    assert_includes @prompt, "## Hard Constraints"
    assert_includes @prompt, "LIMIT of 25 or less"
    assert_includes @prompt, "## Response Format"
    assert_includes @prompt, '"refusal"'
  end
end
