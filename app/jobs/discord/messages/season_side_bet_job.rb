module Discord
  module Messages
    class SeasonSideBetJob < BaseJob

      private

      def channel
        Discord::Channels::SideHustles
      end

      def content
        <<~CONTENT
          #{nickname} has placed a new bet!
          Type: #{SeasonSideBet::VALID_BET_TYPES[bet.bet_type.to_sym]}
          Terms: #{bet.terms_description}
          Amount: #{amount}
          Closes: #{bet.closing_date.to_date}
          Open To: #{possible_acceptors}
        CONTENT
      end

      def amount
        base = ActionController::Base.helpers.number_to_currency(bet.amount)
        bet.odds && bet.odds != "1:1" ?  base + ", paying #{bet.odds}" : base
      end

      def nickname
        bet.user.random_nickname
      end

      def possible_acceptors
        if bet.possible_acceptances&.dig("any")
          "Anyone"
        elsif bet.possible_acceptances&.dig("users")
          bet.possible_acceptances["users"].map { |id| User.find(id).random_nickname }
        elsif bet.maximum_acceptors
          bet.maximum_acceptors > 1 ? "First #{bet.maximum_acceptors} Takers" : "First Taker"
        end
      end
    end
  end
end