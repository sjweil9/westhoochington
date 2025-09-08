module Discord
  module Bots
    module Commands
      class Seasons < Discord::Bots::Commands::Base
        def name
          :seasons
        end

        def execute(event, *args)
          direction = args[0]
          return invalid_direction!(event, direction) unless VALID_DIRECTIONS.include?(direction)

          is_avg = false

          if args[1] == "average"
            is_avg = true
            args.delete_at(1)
          end

          stat = args[1]
          return invalid_stat!(event, stat) unless VALID_STATS.include?(stat)

          stat_desc = STAT_DESC_MAPPING[stat]

          arg3 = args[2]
          is_year = arg3.to_i.to_s == arg3 || RANGE_REGEX.match?(arg3)
          return invalid_year!(event, arg3) unless !is_year || valid_year?(arg3)

          user = find_user(arg3) unless is_year || arg3.blank?
          return invalid_user!(event, arg3) unless arg3.blank? || is_year || user

          stat_key = KEY_MAPPING[stat]

          if args.length == 2
            if is_avg
              users = User.where(active: true).joins(:calculated_stats).all.map do |user|
                schedule_stats = user.calculated_stats.schedule_stats.map(&:with_indifferent_access)
                sum = schedule_stats.map { |x| x[stat_key] }.sum
                average = sum / schedule_stats.size
                {
                  user: user,
                  average: average,
                }
              end
              sorted = users.sort_by { |x| direction == "highest" ? -x[:average] : x[:average] }
              msg = "Here are all players sorted by #{direction} average #{stat_desc} in league history"
              event << "#{msg}:"
              sorted.each_with_index do |hash, index|
                event << "#{index + 1}) #{hash[:user].random_nickname} - #{hash[:average]&.round(2)}"
              end
            else
              seasons = User.joins(:calculated_stats).all.map do |user|
                user.calculated_stats.schedule_stats.map(&:with_indifferent_access)
              end.flatten
              sorted = seasons.sort_by { |x| direction == "highest" ? -x[stat_key] : x[stat_key] }
              msg = "Here are the top 10 #{direction} seasons by #{stat_desc} in league history"
              event << "#{msg}:"
              sorted.first(10).each_with_index do |season, index|
                user_id = season["user_id"]
                user = User.find(user_id)
                event << "#{index + 1}) #{user.random_nickname} - #{season['year']} - #{season[stat_key]&.round(2)}"
              end
            end
            # no year / user, just all historical

          elsif args.length == 3 && is_year
            year_desc = if RANGE_REGEX.match?(arg3)
                          start, finish = arg3.split("-")
                          "between #{start} and #{finish}"
                        else
                          "in #{arg3}"
                        end
            if is_avg
              users = User.where(active: true).joins(:calculated_stats).all.map do |user|
                seasons = user.calculated_stats.schedule_stats.map(&:with_indifferent_access)
                relevant = if RANGE_REGEX.match?(arg3)
                             start, finish = arg3.split("-").map(&:to_i)
                             seasons.select { |x| x["year"].to_i >= start && x["year"].to_i <= finish }
                           else
                             seasons.select { |x| x["year"].to_i == arg3.to_i }
                           end
                sum = relevant.map { |x| x[stat_key] }.sum
                {
                  user: user,
                  average: sum / relevant.size,
                }
              end
              sorted = users.sort_by { |hash| direction == "highest" ? -hash[:average] : hash[:average] }
              msg = "Here are all players sorted by #{direction} average #{stat_desc} #{year_desc}"
              event << "#{msg}:"
              sorted.each_with_index do |hash, index|
                event << "#{index + 1})  #{hash[:user].random_nickname} - #{hash[:average]&.round(2)}"
              end
            else
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
              msg = "Here are the top 10 #{direction} seasons by #{stat_desc} #{year_desc}"
              event << "#{msg}:"
              sorted.first(10).each_with_index do |season, index|
                user_id = season["user_id"]
                user = User.find(user_id)
                event << "#{index + 1}) #{user.random_nickname} - #{season['year']} - #{season[stat_key]&.round(2)}"
              end
            end
            # top for a specific year or range of years
          elsif args.length == 3 && user
            # top for a specific user
            msg = "Here are the top #{direction} seasons by #{stat_desc} for #{user.random_nickname}:"
            event << "#{msg}:"
            seasons = user.calculated_stats.schedule_stats.map(&:with_indifferent_access)
            sorted = seasons.sort_by { |x| direction == "highest" ? -x[stat_key] : x[stat_key] }
            sorted.each_with_index do |season, index|
              event << "#{index + 1}) #{season['year']} - #{season[stat_key]&.round(2)}"
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
        }.with_indifferent_access

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
          "seasons [highest/lowest] [average] [pointsfor/pointsagainst/opponentmojo] [@user/year]".freeze
        end

        def invalid_direction!(event, direction)
          event << "Sorry, #{direction} is invalid. Must be either best OR worst."
          nil
        end

        def valid_user?(discord_mention)
          discord_id = discord_mention.gsub(/\D+/, '')
          User.find_by(discord_id: discord_id)&.discord_id.present?
        end
      end
    end
  end
end