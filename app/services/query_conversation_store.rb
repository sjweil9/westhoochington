# In-memory conversation history for StatBot follow-up questions.
#
# Mirrors fantasy-hof's DB-backed LeagueQueryConversation (last 5 Q/A pairs,
# 24h expiry) but keeps everything in process memory since the bot is a
# single long-lived process. `!stats clear` resets a user's conversation.
class QueryConversationStore
  MAX_MESSAGES = 10 # 5 user/assistant pairs
  TTL = 24.hours

  class Conversation
    def initialize
      @messages = []
      @touched_at = Time.current
    end

    attr_reader :touched_at

    def append_message(role:, content:, sql: nil, results_summary: nil)
      entry = { "role" => role, "content" => content }
      entry["sql"] = sql if sql
      entry["results_summary"] = results_summary if results_summary
      @messages = @messages.push(entry).last(MAX_MESSAGES)
      @touched_at = Time.current
    end

    def llm_messages
      @messages.map { |m| { role: m["role"], content: m["content"] } }
    end
  end

  class << self
    def for(user_id)
      mutex.synchronize do
        prune
        conversations[user_id] ||= Conversation.new
      end
    end

    def clear(user_id)
      mutex.synchronize { conversations.delete(user_id) }
    end

    def reset!
      mutex.synchronize { conversations.clear }
    end

    private

    def prune
      conversations.delete_if { |_key, conversation| conversation.touched_at < TTL.ago }
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def conversations
      @conversations ||= {}
    end
  end
end
