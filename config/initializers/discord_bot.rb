require "discordrb"

is_rake = (ENV['RACK_ENV'].blank? || ENV['RAILS_ENV'].blank? || !("#{ENV.inspect}" =~ /worker/i).blank?)

unless is_rake
  bot = Discord::Bots::Stats.new(token: Rails.application.credentials.westhoochington_bot_token, prefix: "!", help_command: :statshelp)

  bot.run(true)

  at_exit do
    bot.stop
  end
end
