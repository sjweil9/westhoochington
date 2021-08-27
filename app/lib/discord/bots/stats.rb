module Discord
  module Bots
    class Stats < ::Discordrb::Commands::CommandBot
      def initialize(*args)
        super(*args)
        setup_commands!
      end

      private

      COMMANDS = [
        Discord::Bots::Commands::Position.instance,
        Discord::Bots::Commands::Games.instance
      ]

      def setup_commands!
        COMMANDS.each do |command|
          command(command.name, **command.opts) do |event, *args|
            command.execute(event, *args)
          end
        end
      end
    end
  end
end