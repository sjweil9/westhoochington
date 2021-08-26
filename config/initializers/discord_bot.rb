require "discordrb"

bot = Discord::Bots::Stats.new(token: Rails.application.credentials.westhoochington_bot_token, prefix: "!", help_command: "statshelp")

bot.run(true)

at_exit do
  bot.stop
end