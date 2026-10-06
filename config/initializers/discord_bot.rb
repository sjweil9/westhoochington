require "discordrb"

# solution from: https://stackoverflow.com/questions/15538587/how-do-i-detect-in-rails-if-i-am-running-a-rake-command
is_rake = (ENV['RACK_ENV'].blank? || ENV['RAILS_ENV'].blank? || !("#{ENV.inspect}" =~ /worker/i).blank?)

unless !Rails.env.development? && is_rake
  bot_token = ENV["WESTHOOCHINGTON_BOT_TOKEN"].presence
  bot_token ||= begin
    Rails.application.credentials.westhoochington_bot_token
  rescue ActiveSupport::EncryptedFile::MissingKeyError, OpenSSL::Cipher::CipherError,
         ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  if bot_token.present?
    bot = Discord::Bots::Stats.new(token: bot_token, prefix: "!", help_command: :statshelp)

    bot.run(true)

    at_exit do
      bot.stop
    end
  else
    Rails.logger&.warn(
      "[discord_bot initializer] No bot token available (set WESTHOOCHINGTON_BOT_TOKEN " \
      "or fix Rails credentials) — Discord bot not started."
    )
  end
end
