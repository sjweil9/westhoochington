module Discord
  module Channels
    class SideHustles < Base
      def webhook_url
        #Rails.application.credentials.side_hustles_webhook.freeze
        Rails.application.credentials.testing_webhook.freeze
      end
    end
  end
end