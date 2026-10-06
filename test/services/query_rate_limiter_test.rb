require 'test_helper'

class QueryRateLimiterTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @limiter = QueryRateLimiter.new(user_id: @user.id)
  end

  test "allows requests under the limit" do
    assert @limiter.allowed?
    assert_equal QueryRateLimiter::LIMIT, @limiter.remaining
    assert_equal 0, @limiter.reset_in_seconds
  end

  test "counts increments and blocks at the limit" do
    QueryRateLimiter::LIMIT.times { @limiter.increment! }

    assert_equal QueryRateLimiter::LIMIT, @limiter.current_count
    assert_equal 0, @limiter.remaining
    assert_not @limiter.allowed?
    assert @limiter.reset_in_seconds.positive?
    assert_operator @limiter.reset_in_seconds, :<=, QueryRateLimiter::WINDOW.to_i
  end

  test "persists counts in the database so they survive a process restart" do
    @limiter.increment!(question: "what was my best week?")

    record = StatBotQuery.where(user_id: @user.id).last
    assert_equal "what was my best week?", record.question

    # a brand-new limiter (as after a restart) sees the same count
    assert_equal 1, QueryRateLimiter.new(user_id: @user.id).current_count
  end

  test "tracks users independently" do
    QueryRateLimiter::LIMIT.times { @limiter.increment! }

    assert_not @limiter.allowed?
    assert QueryRateLimiter.new(user_id: @other_user.id).allowed?
  end

  test "resets after the window elapses" do
    QueryRateLimiter::LIMIT.times { @limiter.increment! }
    assert_not @limiter.allowed?

    travel(QueryRateLimiter::WINDOW + 1.second) do
      assert @limiter.allowed?
      assert_equal QueryRateLimiter::LIMIT, @limiter.remaining
      assert_equal 0, @limiter.current_count
    end
  end

  test "window slides as old requests age out" do
    @limiter.increment!
    travel(30.minutes) do
      (QueryRateLimiter::LIMIT - 1).times { @limiter.increment! }
      assert_not @limiter.allowed?
    end

    # 61 minutes after the first request it ages out; the 19 made at the
    # 30-minute mark are still in the window
    travel(61.minutes) do
      assert_equal QueryRateLimiter::LIMIT - 1, @limiter.current_count
      assert @limiter.allowed?
    end
  end
end
