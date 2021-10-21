module Discord
  module Bots
    module Commands
      class Lineup < Discord::Bots::Commands::Base
        def name
          :lineup
        end

        def execute(event, *args)
          discord_mention, year, week = args
          discord_id = discord_mention.gsub(/\D+/, '')
          user = User.find_by(discord_id: discord_id)
          return invalid_year!(event, year) unless valid_year?(year)
          return invalid_user!(event, discord_mention) unless user&.discord_id.present?

          game = Game.find_by(season_year: year, week: week, user_id: user.id)
          return invalid_combo!(event, user, year, week) unless game

          event << "Here was the lineup for #{user.random_nickname} for Week #{week} in #{year}:"
          game.player_games.lineup_order.each do |pg|
            msg = "#{pg.lineup_slot}: #{pg.player.name} - #{pg.points.round(2)}"
            msg << " (proj. #{pg.projected_points.round(2)})" if year.to_i >= 2018
            event << msg
          end
          event << ""
          event << "Total Score: #{game.active_total} (#{game.won? ? 'W' : 'L'} vs #{game.opponent.random_nickname})"

          nil
        end

        private

        def valid_year?(year)
          year.to_i >= 2012 && year.to_i <= Date.today.year
        end

        def invalid_user!(event, user)
          event << "Sorry, user #{user} was not recognized."
          nil
        end

        def invalid_year!(event, year)
          event << "Year #{year} is invalid. Must be between 2012 and the present."
          nil
        end

        def invalid_combo!(event, user, year, week)
          event << "Could not find any game for #{user.random_nickname} for Week #{week} in #{year}."
          nil
        end

        def min_args; 3; end
        def max_args; 3; end
        def channels
          Rails.env.production? ? %w[stat-requests].freeze : %w[testing].freeze
        end

        def description
          "Lists the lineup for a particular user on a given week/year combination.".freeze
        end

        def usage
          "lineup [@user] [year] [week]".freeze
        end
      end
    end
  end
end
