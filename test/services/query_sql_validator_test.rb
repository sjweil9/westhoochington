require 'test_helper'

class QuerySqlValidatorTest < ActiveSupport::TestCase
  test "allows a plain select on an allowlisted table" do
    sql = "SELECT active_total FROM games WHERE finished = true ORDER BY active_total DESC LIMIT 10"
    assert_equal sql, QuerySqlValidator.validate!(sql)
  end

  test "allows CTEs and does not flag CTE names as tables" do
    sql = "WITH totals AS (SELECT user_id, SUM(active_total) AS points FROM games GROUP BY user_id) " \
          "SELECT user_id, points FROM totals ORDER BY points DESC LIMIT 10"
    assert_equal sql, QuerySqlValidator.validate!(sql)
  end

  test "rejects non-select statements" do
    assert_raises(QuerySqlValidator::InvalidQueryError) do
      QuerySqlValidator.validate!("EXPLAIN SELECT * FROM games")
    end
  end

  test "rejects forbidden keywords" do
    %w[INSERT UPDATE DELETE DROP ALTER TRUNCATE CREATE GRANT].each do |keyword|
      assert_raises(QuerySqlValidator::InvalidQueryError, "expected #{keyword} to be rejected") do
        QuerySqlValidator.validate!("SELECT * FROM games WHERE #{keyword} = 1")
      end
    end
  end

  test "does not flag forbidden keywords inside string literals" do
    sql = "SELECT * FROM player_faab_transactions WHERE 'drop' = 'drop' LIMIT 5"
    assert_equal sql, QuerySqlValidator.validate!(sql)
  end

  test "rejects semicolons" do
    assert_raises(QuerySqlValidator::InvalidQueryError) do
      QuerySqlValidator.validate!("SELECT * FROM games; SELECT * FROM games")
    end
  end

  test "rejects system catalog references" do
    assert_raises(QuerySqlValidator::InvalidQueryError) do
      QuerySqlValidator.validate!("SELECT * FROM pg_catalog.pg_tables")
    end
  end

  test "rejects tables outside the allowlist" do
    error = assert_raises(QuerySqlValidator::InvalidQueryError) do
      QuerySqlValidator.validate!("SELECT email FROM users LIMIT 5")
    end
    assert_match(/users/, error.message)
  end

  test "rejects over-length SQL" do
    sql = "SELECT * FROM games WHERE #{'1 = 1 AND ' * 700} 1 = 1"
    assert_raises(QuerySqlValidator::InvalidQueryError) do
      QuerySqlValidator.validate!(sql)
    end
  end
end
