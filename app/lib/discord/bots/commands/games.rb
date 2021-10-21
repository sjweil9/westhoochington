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

          direction_instruction = %w[best bestprojected].include?(direction) ? :desc : :asc
          direction_field = %w[bestprojected worstprojected].include?(direction) ? :projected_total : :active_total
          second_arg_is_year = (args.size == 2 || args.size == 3) && (args[1].to_i.to_s == args[1] || RANGE_REGEX.match?(args[1]))
          third_arg_is_year = args.size == 3 && (args[2].to_i.to_s == args[2] || RANGE_REGEX.match?(args[2]))
          tryhard = args.any? { |arg| arg == "tryhard" }
          user_arg = second_arg_is_year ? nil : args[1]
          user_arg = nil if user_arg == "tryhard"
          year_arg = second_arg_is_year ? args[1] : (third_arg_is_year ? args[2] : nil)
          p "user_arg: #{user_arg}, year_arg: #{year_arg}, tryhard: #{tryhard}, direction_instruction: #{direction_instruction}, direction_field: #{direction_field}"

          return invalid_user!(event, user_arg) unless !user_arg || valid_user?(user_arg)
          return invalid_year!(event, year_arg) unless !year_arg || valid_year?(year_arg)

          if args.length == 1
            historical_total(direction_instruction, direction_field, event, tryhard)
          elsif args.length == 2 && tryhard
            historical_total(direction_instruction, direction_field, event, tryhard)
          elsif args.length == 2 && user_arg
            user_total(direction_instruction, direction_field, user_arg, event, tryhard)
          elsif args.length == 2
            year_total(direction_instruction, direction_field, year_arg, event, tryhard)
          elsif args.length == 3 && user_arg
            user_year_total(direction_instruction, direction_field, args[1], args[2], event, tryhard)
          elsif args.length == 3
            year_total(direction_instruction, direction_field, year_arg, event, tryhard)
          elsif args.length == 4
            user_year_total(direction_instruction, direction_field, args[1], args[2], event, tryhard)
          end

          nil
        end

        private

        VALID_DIRECTIONS = %w[best worst bestprojected worstprojected].freeze

        def min_args; 1; end
        def max_args; 4; end
        def channels
          Rails.env.production? ? %w[stat-requests].freeze : %w[testing].freeze
        end

        def description
          "Lists the best games for the league, by year or by player.".freeze
        end

        def usage
          "games [best/worst/bestprojected/worstprojected] [@user/year/tryhard] [year/tryhard] [tryhard]".freeze
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

        def historical_total(direction, direction_field, event, tryhard)
          games = Game.without_two_week_playoffs.includes(*GAME_INCLUDES).references(*GAME_INCLUDES).order(direction_field => direction)
          games = games.where.not(id: PlayerGame.where(active: true, projected_points: 0).select(:game_id)) if tryhard
          games = games.where("season_year >= 2018") if direction_field == :projected_total
          msg = "Here are the top 10 #{direction == :asc ? 'lowest' : 'highest'} #{direction_field == :projected_total ? 'projected ' : ''}1-week scores in league history"
          msg << " (excluding games where a player projected to score zero was started)" if tryhard
          event << "#{msg}:"
          games.first(10).each_with_index do |game, index|
            event << "#{index + 1}) #{game.send(direction_field)}#{direction_field == :projected_total ? " (#{game.active_total} final)" : ""} -- #{game.user.random_nickname} vs #{game.opponent.random_nickname} -- #{game.season_year}, Week #{game.week}"
          end
        end

        def year_total(direction, direction_field, year, event, tryhard)
          if RANGE_REGEX.match?(year)
            start, finish = year.split("-")
            year = (start..finish)
          end
          games = Game.without_two_week_playoffs.includes(*GAME_INCLUDES).references(*GAME_INCLUDES).where(season_year: year).order(direction_field => direction)
          games = games.where.not(id: PlayerGame.where(active: true, projected_points: 0).select(:game_id)) if tryhard
          games = games.where("season_year >= 2018") if direction_field == :projected_total
          msg = "Here are the top 10 #{direction == :asc ? 'lowest' : 'highest'} #{direction_field == :projected_total ? 'projected ' : ''}1-week scores from #{year}"
          msg << " (excluding games where a player projected to score zero was started)" if tryhard
          event << "#{msg}:"
          games.first(10).each_with_index do |game, index|
            event << "#{index + 1}) #{game.send(direction_field)}#{direction_field == :projected_total ? " (#{game.active_total} final)" : ""} -- #{game.user.random_nickname} vs #{game.opponent.random_nickname} -- Week #{game.week}"
          end
        end

        def user_total(direction, direction_field, discord_mention, event, tryhard)
          discord_id = discord_mention.gsub(/\D+/, '')
          user = User.find_by(discord_id: discord_id)
          games = Game.without_two_week_playoffs.includes(*GAME_INCLUDES).references(*GAME_INCLUDES).where(user_id: user.id).order(direction_field => direction)
          games = games.where.not(id: PlayerGame.where(active: true, projected_points: 0).select(:game_id)) if tryhard
          games = games.where("season_year >= 2018") if direction_field == :projected_total
          msg = "Here are the top 10 #{direction == :asc ? 'lowest' : 'highest'} #{direction_field == :projected_total ? 'projected ' : ''}1-week scores by #{user.random_nickname}"
          msg << " (excluding games where a player projected to score zero was started)" if tryhard
          event << "#{msg}:"
          games.first(10).each_with_index do |game, index|
            event << "#{index + 1}) #{game.send(direction_field)}#{direction_field == :projected_total ? " (#{game.active_total} final)" : ""} -- #{game.user.random_nickname} vs #{game.opponent.random_nickname} -- #{game.season_year}, Week #{game.week}"
          end
        end

        def user_year_total(direction, direction_field, discord_mention, year, event, tryhard)
          discord_id = discord_mention.gsub(/\D+/, '')
          user = User.find_by(discord_id: discord_id)
          if RANGE_REGEX.match?(year)
            start, finish = year.split("-")
            year = (start..finish)
          end
          games = Game.without_two_week_playoffs.includes(*GAME_INCLUDES).references(*GAME_INCLUDES).where(user_id: user.id, season_year: year).order(direction_field => direction)
          games = games.where.not(id: PlayerGame.where(active: true, projected_points: 0).select(:game_id)) if tryhard
          games = games.where("season_year >= 2018") if direction_field == :projected_total
          msg = "Here are the top 5 #{direction == :asc ? 'lowest' : 'highest'} #{direction_field == :projected_total ? 'projected ' : ''}1-week scores by #{user.random_nickname} in #{year}:"
          msg << " (excluding games where a player projected to score zero was started)" if tryhard
          event << "#{msg}:"
          games.first(5).each_with_index do |game, index|
            event << "#{index + 1}) #{game.send(direction_field)}#{direction_field == :projected_total ? " (#{game.active_total} final)" : ""} -- #{game.user.random_nickname} vs #{game.opponent.random_nickname} -- #{game.season_year}, Week #{game.week}"
          end
        end
      end
    end
  end
end