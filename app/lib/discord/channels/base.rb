require "discordrb/webhooks"

module Discord
  module Channels
    class Base
      def self.send_message(content: nil, embeds: [])
        new(content: content, embeds: embeds).call
      end

      def initialize(content: nil, embeds: [])
        @content = content
        @embeds = embeds
      end

      def call
        client.execute do |builder|
          builder.content = content
          embeds.each do |embed_params|
            builder.add_embed do |e|
              e.title = embed_params[:title] if embed_params[:title]
              e.description = embed_params[:description] if embed_params[:description]
              e.timestamp = embed_params[:timestamp] if embed_params[:timestamp]
            end
          end
        end
      end

      private

      attr_reader :content, :embeds

      def client
        @client ||= Discordrb::Webhooks::Client.new(url: webhook_url)
      end

      def webhook_url
        raise NotImplementedError
      end
    end
  end
end