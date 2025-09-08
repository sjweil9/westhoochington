module Discord
  module Bots
    module Commands
      class Games < Discord::Bots::Commands::Base
        def name
          :seasons
        end

        def execute(event, *args)
          direction = args[0]
          return invalid_direction!(event, direction) unless VALID_DIRECTIONS.include?(direction)

          stat = args[1]
          return invalid_stat!(event, stat) unless VALID_STATS.include?(stat)

          stat_desc = STAT_DESC_MAPPING[stat]

          arg3 = args[2]
          is_year = arg3.to_i.to_s == arg3 || RANGE_REGEX.match?(arg3)
          return invalid_year!(event, arg3) unless !is_year || valid_year?(arg3)

          user = find_user(arg3) unless is_year
          return invalid_user!(event, arg3) unless is_year || user

          stat_key = KEY_MAPPING[stat]

          if args.length == 2
            # no year / user, just all historical
            seasons = User.joins(:calculated_stats).all.map do |user|
              user.calculated_stats.schedule_stats.map(&:with_indifferent_access)
            end.flatten
            sorted = seasons.sort_by { |x| direction == "highest" ? -x[stat_key] : x[stat_key] }
            msg = "Here are the top 10 #{direction} seasons by #{stat_desc} in league history"
            event << "#{msg}:"
            sorted.first(10).each_with_index do |season, index|
              user_id = season["user_id"]
              user = User.find(user_id)
              event << "#{index + 1}) #{user.random_nickname} - #{season['year']} - #{season[stat_key]}"
            end
          elsif args.length == 3 && is_year
            # top for a specific year or range of years
            seasons = User.joins(:calculated_stats).all.map do |user|
              user.calculated_stats.schedule_stats.map(&:with_indifferent_access)
            end.flatten
            relevant = if RANGE_REGEX.match?(arg3)
                         start, finish = arg3.split("-").map(&:to_i)
                         seasons.select { |x| x["year"].to_i >= start && x["year"].to_i <= finish }
                       else
                         seasons.select { |x| x["year"].to_i == arg3.to_i }
                       end
            sorted = relevant.sort_by { |x| direction == "highest" ? -x[stat_key] : x[stat_key] }
            year_desc = if RANGE_REGEX.match?(arg3)
                          start, finish = arg3.split("-")
                          "between #{start} and #{finish}."
                        else
                          "in #{arg3}."
                        end
            msg = "Here are the top 10 #{direction} seasons by #{stat_desc} #{year_desc}"
            event << "#{msg}:"
            sorted.first(10).each_with_index do |season, index|
              user_id = season["user_id"]
              user = User.find(user_id)
              event << "#{index + 1}) #{user.random_nickname} - #{season['year']} - #{season[stat_key]}"
            end
          elsif args.length == 3 && user
            # top for a specific user
            msg = "Here are the top #{direction} seasons by #{stat_desc} for #{user.random_nickname}:"
            event << "#{msg}:"
            seasons = user.calculated_stats.schedule_stats.map(&:with_indifferent_access)
            sorted = seasons.sort_by { |x| direction == "highest" ? -x[stat_key] : x[stat_key] }
            sorted.each_with_index do |season, index|
              event << "#{index + 1}) #{season['year']} - #{season[stat_key]}"
            end
          end

          nil
        end

        private

        VALID_DIRECTIONS = %w[highest lowest].freeze
        VALID_STATS = %w[pointsfor pointsagainst opponentmojo]

        KEY_MAPPING = {
          pointsfor: "points_for",
          pointsagainst: "points_against",
          opponentmojo: "opponent_pts_above_avg"
        }.with_indifferent_access

        STAT_DESC_MAPPING = {
          pointsfor: "Avg Points For",
          pointsagainst: "Avg Points Against",
          opponentmojo: "Opponent Points Above (their) Average"
        }

        def invalid_stat!(event, stat)
          event << "Stat #{stat} is invalid. Must be one of: #{VALID_STATS.join(', ')}."
          nil
        end

        def min_args; 2; end
        def channels
          Rails.env.production? ? %w[stat-requests].freeze : %w[testing].freeze
        end

        def description
          "Lists the best seasons for the league.".freeze
        end

        def usage
          "seasons [highest/lowest] [pointsfor/pointsagainst/mojo/mojoagainst] [@user/year]".freeze
        end

        def invalid_direction!(event, direction)
          event << "Sorry, #{direction} is invalid. Must be either best OR worst."
          nil
        end

        def valid_user?(discord_mention)
          discord_id = discord_mention.gsub(/\D+/, '')
          User.find_by(discord_id: discord_id)&.discord_id.present?
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

        def user_total(direction, direction_field, user, event, tryhard)
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

        def user_year_total(direction, direction_field, user, year, event, tryhard)
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