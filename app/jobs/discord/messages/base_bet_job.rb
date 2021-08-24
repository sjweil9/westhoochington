require Rails.root.join("app/lib/discord")

module Discord
  module Messages
    class BaseBetJob < ApplicationJob
      def perform(bet)
        @bet = bet
        channel.send_message(content: content, embeds: embeds)
      end

      private

      attr_reader :bet

      def embeds
        []
      end

      def channel
        raise NotImplementedError
      end

      def content; end

      def to_currency(amount)
        ActionController::Base.helpers.number_to_currency(amount)
      end

      def amount
        base = to_currency(bet.amount)
        bet.odds && bet.odds != "1:1" ?  base + ", paying #{bet.odds}" : base
      end

      def amount_clarification
        return unless bet.odds && bet.odds != "1:1"

        "(If you accept, you risk #{risk_amount} to win #{win_amount})"
      end

      def win_amount
        win_weight, _ = bet.odds.split(":")
        to_currency(bet.amount * win_weight.to_f)
      end

      def risk_amount
        _, risk_weight = bet.odds.split(":")
        to_currency(bet.amount * risk_weight.to_f)
      end

      def nickname
        bet.user.discord_mention
      end

      def possible_acceptors
        if bet.possible_acceptances&.dig("any")
          "Anyone"
        elsif bet.possible_acceptances&.dig("users")
          bet.possible_acceptances["users"].map { |id| User.find(id).discord_mention }.join(", ")
        elsif bet.maximum_acceptors
          bet.maximum_acceptors > 1 ? "First #{bet.maximum_acceptors} Takers" : "First Taker"
        end
      end

      def player_nickname
        bet.game.user.discord_mention
      end

      def opponent_nickname
        bet.game.opponent.discord_mention
      end
    end
  end
end