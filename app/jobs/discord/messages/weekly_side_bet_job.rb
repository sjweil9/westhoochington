module Discord
  module Messages
    class WeeklySideBetJob < BaseBetJob

      private

      def channel
        Discord::Channels::SideHustles
      end

      def content
        <<~CONTENT
          #{nickname} has placed a new bet for Week #{bet.week}!
          Type: #{WeeklySideBet::BET_TYPE_DESCRIPTIONS[bet.comparison_type.to_sym]}
          Terms: #{bet.terms_description}
          Amount: #{amount} #{amount_clarification}
          Open To: #{possible_acceptors}
          Visit https://www.westhoochington.com/side_bets to take this action!
        CONTENT
      end
    end
  end
end
