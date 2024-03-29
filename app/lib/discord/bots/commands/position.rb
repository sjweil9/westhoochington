module Discord
  module Bots
    module Commands
      class Position < Discord::Bots::Commands::Base
        def name
          :position
        end

        def execute(event, *args)
          return invalid_position!(event, args[0]) unless VALID_POSITIONS.include?(args[0])
          second_arg_is_year = args[1].to_i.to_s == args[1] || RANGE_REGEX.match?(args[1])
          user_arg = second_arg_is_year ? nil : args[1]
          year_arg = second_arg_is_year ? args[1] : args[2]
          user = find_user(user_arg) if user_arg
          return invalid_user!(event, user_arg) unless !user_arg || user
          return invalid_year!(event, year_arg) unless !year_arg || valid_year?(year_arg)

          case args.length
          when 1 then position_total(args[0], event)
          when 2 then second_arg_is_year ? year_total(args[0], year_arg, event) : user_total(args[0], user, event)
          when 3 then user_year_total(args[0], user, args[2], event)
          end

          nil
        end

        private

        VALID_POSITIONS = %w[QB RB WR TE DST K].freeze

        def min_args; 1; end
        def channels
          Rails.env.production? ? %w[stat-requests].freeze : %w[testing].freeze
        end

        def description
          "Gives stats on how much the league or a specific player scored for a certain position.".freeze
        end

        def usage
          "position [QB/RB/WR/TE/DST/K] [@user/year] [year]".freeze
        end

        def user_year_total(position, user_record, year, event)
          if RANGE_REGEX.match?(year)
            start, finish = year.split("-")
            year = (start..finish)
          end
          results = ratio_for_user(user_record, position, year)
          event << "#{user_record.random_nickname} scored #{results[:position_ppg]} ppg from the #{position} position in #{year}, representing #{results[:percentage]}% of their points (#{results[:position].round(2).to_s(:delimited)} / #{results[:total].round(2).to_s(:delimited)})."
          position_games = PlayerGame.joins(:game).where(active: true, default_lineup_slot: position, games: { season_year: year }).all
          position_points = position_games.sum(&:points)
          overall_position_ppg = (position_points / total_games_factoring_playoffs(position_games)).round(2)
          total_points = PlayerGame.joins(:game).where(active: true, games: { season_year: year }).all.sum(&:points)
          percentage = ((position_points / total_points) * 100).round(2)
          event << "#{percentage}% of all points in #{year} (#{position_points.round(2).to_s(:delimited)} / #{total_points.round(2).to_s(:delimited)}) come from the #{position} position (#{overall_position_ppg} ppg)."
        end

        def user_total(position, user_record, event)
          results = ratio_for_user(user_record, position)
          event << "#{user_record.random_nickname} has scored a lifetime average of #{results[:position_ppg]} ppg from the #{position} position, amounting to #{results[:percentage]}% of their lifetime points (#{results[:position].round(2).to_s(:delimited)} / #{results[:total].round(2).to_s(:delimited)})."
          position_games = PlayerGame.includes(:game).where(active: true, default_lineup_slot: position).all
          position_points = position_games.sum(&:points)
          overall_position_ppg = (position_points / total_games_factoring_playoffs(position_games)).round(2)
          total_points = PlayerGame.where(active: true).all.sum(&:points)
          percentage = ((position_points / total_points) * 100).round(2)
          event << "#{percentage}% of all points in League History (#{position_points.round(2).to_s(:delimited)} / #{total_points.round(2).to_s(:delimited)}) come from the #{position} position (#{overall_position_ppg} ppg)."
        end

        def year_total(position, year, event)
          if RANGE_REGEX.match?(year)
            start, finish = year.split("-")
            year = (start..finish)
          end
          conditions = { active: true, games: { season_year: year } }
          position_games = PlayerGame.joins(:game).where(conditions.merge(default_lineup_slot: position)).all
          position_points = position_games.sum(&:points)
          position_ppg = (position_points / total_games_factoring_playoffs(position_games)).round(2)
          total_points = PlayerGame.joins(:game).where(conditions).all.sum(&:points)
          percentage = ((position_points / total_points) * 100).round(2)
          event << "A total of #{position_points.round(2).to_s(:delimited)} points were scored at the #{position} position in #{year}."
          event << "This constitutes #{percentage}% of all #{total_points.round(2).to_s(:delimited)} points scored in #{year}, or an average of #{position_ppg} ppg."
          event << "Here are all league members sorted by the proportion of their points from the #{position} position in #{year}:"
          year_users = Game.where(season_year: year).all.map(&:user).uniq
          results = year_users.reduce([]) do |memo, user|
            results_for_user = ratio_for_user(user, position, year)
            if results_for_user[:total].zero?
              memo
            else
              memo + [results_for_user.merge(user: user.random_nickname)]
            end
          end.sort_by { |hash| -hash[:percentage] }
          results.each_with_index do |result, index|
            event << "#{index + 1}) #{result[:user]} -- #{result[:percentage]}% (#{result[:position].round(2).to_s(:delimited)} / #{result[:total].round(2).to_s(:delimited)}) -- #{result[:position_ppg]} ppg"
          end
        end

        def position_total(position, event)
          position_games = PlayerGame.where(active: true, default_lineup_slot: position).all
          position_points = position_games.sum(&:points)
          position_ppg = (position_points / total_games_factoring_playoffs(position_games)).round(2)
          total_points = PlayerGame.where(active: true).all.sum(&:points)
          percentage = ((position_points / total_points) * 100).round(2)
          event << "A total of #{position_points.round(2).to_s(:delimited)} points have been scored at the #{position} position in league history (#{position_ppg} ppg)."
          event << "This constitutes #{percentage}% of all #{total_points.round(2).to_s(:delimited)} points that have been scored in league history."
          event << "Here are all active league members sorted by the proportion of their points from the #{position} position:"
          active_users = User.where(active: true).all
          results = active_users.reduce([]) do |memo, user|
            results_for_user = ratio_for_user(user, position)
            if results_for_user[:total].zero?
              memo
            else
              memo + [results_for_user.merge(user: user.random_nickname)]
            end
          end.sort_by { |hash| -hash[:percentage] }
          results.each_with_index do |result, index|
            event << "#{index + 1}) #{result[:user]} -- #{result[:percentage]}% (#{result[:position].round(2).to_s(:delimited)} / #{result[:total].round(2).to_s(:delimited)}) -- #{result[:position_ppg]} ppg"
          end
        end

        def ratio_for_user(user, position, year = nil, week = nil)
          filter_conditions = { active: true, user_id: user.id }.compact
          game_conditions = { season_year: year, week: week }.compact
          total_conditions = game_conditions.present? ? filter_conditions.merge(games: game_conditions) : filter_conditions
          total_games = PlayerGame.joins(:game).where(total_conditions).all
          total_points = total_games.sum(&:points)
          position_games = PlayerGame.joins(:game).where(total_conditions.merge(default_lineup_slot: position)).all
          position_points = position_games.sum(&:points)
          percentage = total_points.zero? ? 0.0 : ((position_points / total_points) * 100).round(2)
          position_ppg = (position_points / total_games_factoring_playoffs(position_games)).round(2)
          { total: total_points, position: position_points, percentage: percentage, position_ppg: position_ppg }
        end

        def invalid_position!(event, position)
          event << "Invalid position #{position}. Must be one of #{VALID_POSITIONS.join(', ')}."
          nil
        end

        def total_games_factoring_playoffs(player_games)
          player_games.reduce(0.0) do |memo, player_game|
            memo + (player_game.game.two_game_playoff? ? 2.0 : 1.0)
          end
        end
      end
    end
  end
end