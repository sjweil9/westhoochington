module Discord
  module Messages
    class SideBetAcceptanceJob < BaseBetJob

      private

      def acceptance
        @bet
      end

      def bet
        @bet.side_bet
      end

      def channel
        Discord::Channels::SideHustles
      end

      def acceptor_nickname
        acceptance.user.discord_mention
      end

      def content
        <<~CONTENT
          #{acceptor_nickname} has taken some action!
          Type: #{matchup_type}
          Terms: #{bet.terms_description}
          Proposed By: #{bet.user.discord_mention}
          Amount: #{amount} #{amount_clarification}
        CONTENT
      end

      def matchup_type
        if bet.is_a?(GameSideBet)
          "Weekly Matchup - #{player_nickname} vs #{opponent_nickname}"
        elsif bet.is_a?(SeasonSideBet)
          SeasonSideBet::VALID_BET_TYPES[bet.bet_type.to_sym]
        end
      end

      def amount_clarification
        return unless bet.odds && bet.odds != "1:1"

        "(#{acceptor_nickname} risks #{risk_amount} to win #{win_amount})"
      end
    end
  end
end