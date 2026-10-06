# Validates the raw user prompt before it is sent to the LLM.
#
# Defense-in-depth alongside QuerySqlValidator and the strict response-shape
# allowlist in StatsQueryService: rejects over-length input, raw SQL, and
# common prompt-injection markers. Returns a user-facing error string, or
# nil when the prompt is acceptable.
#
# Usage:
#   StatsPromptValidator.error_for("What was my best week ever?") # => nil
class StatsPromptValidator
  MAX_LENGTH = 500

  EMPTY_MESSAGE = "Ask me a question about league stats, e.g. `!stats what are the 5 highest scores in league history?` (`!stats clear` resets our conversation).".freeze
  TOO_LONG_MESSAGE = "That question is too long — keep it under #{MAX_LENGTH} characters.".freeze
  REJECTED_MESSAGE = "That doesn't look like a league stats question I can help with. Ask about scores, records, matchups, drafts, FAAB, side bets, or best ball.".freeze

  PROMPT_INJECTION_PATTERNS = [
    /\bignore\s+(?:all\s+|any\s+)?(?:previous|prior|above|earlier)\s+(?:instructions|prompts|rules|messages)\b/i,
    /\bdisregard\s+(?:the\s+)?(?:system|previous|prior|above|your)\s+(?:prompt|instructions|rules)\b/i,
    /\bsystem\s+prompt\b/i,
    /\byou\s+are\s+now\b/i,
    /\bnew\s+instructions?\s*:/i,
    /\bdeveloper\s+mode\b/i,
    /\bjailbreak\b/i,
    /\b(?:reveal|show|print|repeat)\b[^.?!]{0,40}\b(?:prompt|instructions)\b/i,
    /\bpretend\s+(?:to\s+be|you(?:'re|\s+are))\b/i,
    /<\s*\/?\s*(?:system|assistant|im_start|im_end)\b/i
  ].freeze

  SQL_INJECTION_PATTERNS = [
    /;\s*(?:select|insert|update|delete|drop|alter|create|truncate|grant|revoke)\b/i,
    /\bunion\s+(?:all\s+)?select\b/i,
    /\bselect\b[\s\S]{0,200}?\bfrom\b/i,
    /\binsert\s+into\b/i,
    /\bupdate\s+\w+\s+set\b/i,
    /\bdelete\s+from\b/i,
    /\b(?:drop|alter|truncate)\s+table\b/i,
    /\bor\s+1\s*=\s*1\b/i,
    %r{/\*|\*/},
    /--\s/
  ].freeze

  def self.error_for(question)
    new(question).error
  end

  def initialize(question)
    @question = question.to_s.strip
  end

  def error
    return EMPTY_MESSAGE if @question.blank?
    return TOO_LONG_MESSAGE if @question.length > MAX_LENGTH
    return REJECTED_MESSAGE if control_characters?
    return REJECTED_MESSAGE if matches_any?(PROMPT_INJECTION_PATTERNS)
    return REJECTED_MESSAGE if matches_any?(SQL_INJECTION_PATTERNS)

    nil
  end

  private

  def control_characters?
    @question.match?(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/)
  end

  def matches_any?(patterns)
    patterns.any? { |pattern| @question.match?(pattern) }
  end
end
