# One row per StatBot (!stats) request. The datastore behind
# QueryRateLimiter's sliding window — durable so process crashes/restarts
# can't be used to bypass the limit — and a usage log as a side benefit.
class StatBotQuery < ApplicationRecord
  belongs_to :user
end
