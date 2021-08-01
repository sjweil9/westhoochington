module Discord
  module Messages
    class SeasonSideBetJob < BaseBetJob

      private

      def channel
        Discord::Channels::SideHustles
      end

      def content
        <<~CONTENT
          #{nickname} has placed a new bet!
          Type: #{SeasonSideBet::VALID_BET_TYPES[bet.bet_type.to_sym]}
          Terms: #{bet.terms_description}
          Amount: #{amount} #{amount_clarification}
          Closes: #{bet.closing_date.to_date.strftime('%A, %b %e, %Y')}
          Open To: #{possible_acceptors}
          Visit https://www.westhoochington.com/side_bets to take this action!
        CONTENT
      end
    end
  end
end