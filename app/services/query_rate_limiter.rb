# Per-user hourly cap on StatBot queries, backed by the database.
#
# Mirrors fantasy-hof's Redis-backed QueryRateLimiter interface, but counts
# stat_bot_queries rows in a sliding one-hour window. The counts are durable,
# so a process crash/restart can't be used to bypass the limit (an in-memory
# counter would reset).
class QueryRateLimiter
  LIMIT = 20
  WINDOW = 1.hour

  def initialize(user_id:)
    @user_id = user_id
  end

  def allowed?
    remaining.positive?
  end

  def increment!(question: nil)
    StatBotQuery.create!(user_id: @user_id, question: question)
    current_count
  end

  def remaining
    [LIMIT - current_count, 0].max
  end

  # Seconds until the oldest in-window request ages out (i.e. a slot opens).
  def reset_in_seconds
    oldest = window_scope.minimum(:created_at)
    return 0 unless oldest

    [(oldest + WINDOW - Time.current).ceil, 0].max
  end

  def current_count
    window_scope.count
  end

  private

  def window_scope
    StatBotQuery.where(user_id: @user_id).where("created_at > ?", WINDOW.ago)
  end
end
