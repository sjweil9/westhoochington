module Discord
  module Channels
    class WeeklyWesthoochington < Base
      def webhook_url
        Rails.env.production? ? Rails.application.credentials.weekly_westhoochington_webhook.freeze : Rails.application.credentials.testing_webhook.freeze
      end
    end
  end
end