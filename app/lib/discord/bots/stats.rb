module Discord
  module Bots
    class Stats < ::Discordrb::Commands::CommandBot
      def initialize(**args)
        super(**args)
        setup_commands!
      end

      private

      # The natural-language !stats command replaces the legacy hand-rolled
      # commands (Position, Games, Lineup, Seasons), which remain on disk
      # but are no longer registered.
      COMMANDS = [
        Discord::Bots::Commands::Stats.instance
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