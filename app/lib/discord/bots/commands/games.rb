module Discord
  module Bots
    module Commands
      class Games < Discord::Bots::Commands::Base
        def name
          :games
        end

        def execute(event, *args)
          direction = args[0]
          return invalid_direction!(event, direction) unless VALID_DIRECTIONS.include?(direction)

          direction_instruction = direction == "best" ? :desc : :asc
          second_arg_is_year = args.size == 2 && (args[1].to_i.to_s == args[1] || RANGE_REGEX.match?(args[1]))
          user_arg = second_arg_is_year ? nil : args[1]
          year_arg = second_arg_is_year ? args[1] : args[2]
          return invalid_user!(event, user_arg) unless !user_arg || valid_user?(user_arg)
          return invalid_year!(event, year_arg) unless !year_arg || valid_year?(year_arg)

          case args.length
          when 1 then historical_total(direction_instruction, event)
          when 2 then second_arg_is_year ? year_total(direction_instruction, year_arg, event) : user_total(direction_instruction, user_arg, event)
          when 3 then user_year_total(direction_instruction, args[1], args[2], event)
          end

          nil
        end

        private

        VALID_DIRECTIONS = %w[best worst].freeze

        def min_args; 1; end
        def max_args; 3; end
        def channels
          Rails.env.production? ? %w[stat-requests].freeze : %w[testing].freeze
        end

        def description
          "Lists the best games for the league, by year or by player.".freeze
        end

        def usage
          "games [best/worst] [@user/year] [year]".freeze
        end

        def invalid_direction!(event, direction)
          event << "Sorry, #{direction} is invalid. Must be either best OR worst."
          nil
        end

        def invalid_user!(event, user)
          event << "Sorry, user #{user} was not recognized."
          nil
        end

        def invalid_year!(event, year)
          event << "Year #{year} is invalid. Must be between 2012 and the present."
          nil
        end

        def valid_user?(discord_mention)
          discord_id = discord_mention.gsub(/\D+/, '')
          User.find_by(discord_id: discord_id)&.discord_id.present?
        end

        def valid_year?(year)
          if RANGE_REGEX.match?(year)
            start, finish = year.split("-")
            valid_year?(start) && valid_year?(finish)
          else
            year.to_i >= 2012 && year.to_i <= Date.today.year
          end
        end

        GAME_INCLUDES = %i[player_games user opponent].freeze

        def historical_total(direction, event)
          games = Game.without_two_week_playoffs.includes(*GAME_INCLUDES).references(*GAME_INCLUDES).order(:active_total => direction).first(10)
          event << "Here are the top 10 #{direction == :asc ? 'lowest' : 'highest'} 1-week scores in league history:"
          games.each_with_index do |game, index|
            event << "#{index + 1}) #{game.active_total} -- #{game.user.random_nickname} vs #{game.opponent.random_nickname} -- #{game.season_year}, Week #{game.week}"
          end
        end

        def year_total(direction, year, event)
          if RANGE_REGEX.match?(year)
            start, finish = year.split("-")
            year = (start..finish)
          end
          games = Game.without_two_week_playoffs.includes(*GAME_INCLUDES).references(*GAME_INCLUDES).where(season_year: year).order(:active_total => direction).first(10)
          event << "Here are the top 10 #{direction == :asc ? 'lowest' : 'highest'} 1-week scores from #{year}:"
          games.each_with_index do |game, index|
            event << "#{index + 1}) #{game.active_total} -- #{game.user.random_nickname} vs #{game.opponent.random_nickname} -- Week #{game.week}"
          end
        end

        def user_total(direction, discord_mention, event)
          discord_id = discord_mention.gsub(/\D+/, '')
          user = User.find_by(discord_id: discord_id)
          games = Game.without_two_week_playoffs.includes(*GAME_INCLUDES).references(*GAME_INCLUDES).where(user_id: user.id).order(:active_total => direction).first(10)
          event << "Here are the top 10 #{direction == :asc ? 'lowest' : 'highest'} 1-week scores by #{user.random_nickname}:"
          games.each_with_index do |game, index|
            event << "#{index + 1}) #{game.active_total} -- #{game.user.random_nickname} vs #{game.opponent.random_nickname} -- #{game.season_year}, Week #{game.week}"
          end
        end

        def user_year_total(direction, discord_mention, year, event)
          discord_id = discord_mention.gsub(/\D+/, '')
          user = User.find_by(discord_id: discord_id)
          if RANGE_REGEX.match?(year)
            start, finish = year.split("-")
            year = (start..finish)
          end
          games = Game.without_two_week_playoffs.includes(*GAME_INCLUDES).references(*GAME_INCLUDES).where(user_id: user.id, season_year: year).order(:active_total => direction).first(5)
          event << "Here are the top 5 #{direction == :asc ? 'lowest' : 'highest'} 1-week scores by #{user.random_nickname} in #{year}:"
          games.each_with_index do |game, index|
            event << "#{index + 1}) #{game.active_total} -- #{game.user.random_nickname} vs #{game.opponent.random_nickname} -- #{game.season_year}, Week #{game.week}"
          end
        end
      end
    end
  end
end