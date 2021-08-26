require "discordrb"

# solution from: https://stackoverflow.com/questions/15538587/how-do-i-detect-in-rails-if-i-am-running-a-rake-command
is_rake = (ENV['RACK_ENV'].blank? || ENV['RAILS_ENV'].blank? || !("#{ENV.inspect}" =~ /worker/i).blank?)

unless is_rake
  bot = Discord::Bots::Stats.new(token: Rails.application.credentials.westhoochington_bot_token, prefix: "!", help_command: :statshelp)

  bot.run(true)

  at_exit do
    bot.stop
  end
end
