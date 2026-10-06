module Discord
  module Bots
    module Commands
      # !stats <natural language question> — answers league stats questions
      # via the Anthropic API (see docs/stat_bot/ARCHITECTURE.md).
      # !stats clear — resets the asker's follow-up conversation.
      class Stats < Discord::Bots::Commands::Base
        CLEAR_KEYWORDS = %w[clear reset].freeze

        def name
          :stats
        end

        def execute(event, *args)
          question = args.join(" ").strip

          user = find_tracked_user(event)
          return untracked_user!(event) unless user

          return clear_conversation!(event, user) if CLEAR_KEYWORDS.include?(question.downcase)

          if (error = StatsPromptValidator.error_for(question))
            event << error
            return nil
          end

          rate_limiter = QueryRateLimiter.new(user_id: user.id)
          return rate_limited!(event, rate_limiter) unless rate_limiter.allowed?

          rate_limiter.increment!(question: question)
          start_typing(event)

          conversation = QueryConversationStore.for(user.id)
          result = StatsQueryService.new(user: user, question: question, conversation: conversation).call

          deliver(event, result, rate_limiter)
          nil
        rescue StandardError => e
          Rails.logger.error("[Stats] Unhandled error: #{e.class}: #{e.message}")
          event << "Something went wrong. Please try again."
          nil
        end

        private

        # The question is free text — bypass Base's quoted-argument parsing,
        # which mangles (and can crash on) unbalanced quotes.
        def raw_args?
          true
        end

        def min_args; 1; end

        def channels
          Rails.env.production? ? %w[stat-requests testing].freeze : %w[testing].freeze
        end

        def description
          "Answers natural language questions about league stats (e.g. !stats what was my best week ever?).".freeze
        end

        def usage
          "stats [question] | stats clear".freeze
        end

        def find_tracked_user(event)
          discord_id = event.user&.id
          return nil unless discord_id

          User.find_by(discord_id: discord_id.to_s)
        end

        def untracked_user!(event)
          event << "Sorry, I only answer questions for known league members. Ask the commish to link your Discord account."
          nil
        end

        def clear_conversation!(event, user)
          QueryConversationStore.clear(user.id)
          event << "Conversation cleared. Ask me something fresh!"
          nil
        end

        def rate_limited!(event, rate_limiter)
          minutes = (rate_limiter.reset_in_seconds / 60.0).ceil
          event << "You've used all #{QueryRateLimiter::LIMIT} questions for this hour. Try again in #{minutes} minute#{'s' unless minutes == 1}."
          nil
        end

        def start_typing(event)
          event.channel.start_typing
        rescue StandardError => e
          Rails.logger.warn("[Stats] start_typing failed: #{e.class}: #{e.message}")
        end

        # Embed side-bar colors per result type
        EMBED_COLORS = {
          "result" => 0x57F287,        # green
          "clarification" => 0xFEE75C, # yellow
          "refusal" => 0x95A5A6,       # grey
          "error" => 0xED4245          # red
        }.freeze

        def deliver(event, result, rate_limiter)
          payloads = embed_payloads(result)
          color = EMBED_COLORS.fetch(result[:type], 0x95A5A6)
          footer = "#{rate_limiter.remaining} of #{QueryRateLimiter::LIMIT} questions left this hour"

          payloads.each_with_index do |payload, index|
            send_embed(event, payload, color, index == payloads.size - 1 ? footer : nil)
          end
        end

        def embed_payloads(result)
          return result[:messages] if result[:type] == "result"

          [{ title: nil, description: result[:content] }]
        end

        def send_embed(event, payload, color, footer_text)
          embed = Discordrb::Webhooks::Embed.new(
            title: payload[:title],
            description: payload[:description],
            colour: color
          )
          embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: footer_text) if footer_text

          event.respond("", false, embed)
        rescue StandardError => e
          # Embeds need the "Embed Links" permission — fall back to plain text
          Rails.logger.warn("[Stats] Embed send failed, falling back to text: #{e.class}: #{e.message}")
          event.respond([payload[:title], payload[:description]].compact.join("\n"))
        end
      end
    end
  end
end
