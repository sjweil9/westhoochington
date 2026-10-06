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

  test "includes the member roster with nicknames" do
    assert_includes @prompt, "## League Member Roster"
    assert_includes @prompt, "user_id #{@user.id}: \"Schema Tester\""
  end

  test "identifies the asking user" do
    assert_includes @prompt, "The person asking is user_id #{@user.id}."
  end

  test "includes constraints and response format" do
    assert_includes @prompt, "## Hard Constraints"
    assert_includes @prompt, "LIMIT of 25 or less"
    assert_includes @prompt, "## Response Format"
    assert_includes @prompt, '"refusal"'
  end
end
