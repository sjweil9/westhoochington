require Rails.root.join("app/lib/discord")

module Discord
  module Messages
    class BaseJob < ApplicationJob
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
    end
  end
end