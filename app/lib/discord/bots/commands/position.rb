module Discord
  module Bots
    module Commands
      class Position < Discord::Bots::Commands::Base
        def name
          :position
        end

        def execute(event, *args)
          case args.length
          when 1 then position_total(args[0], event)
          when 2 then user_total(args[0], args[1], event)
          end

          nil
        end

        private

        VALID_POSITIONS = %w[QB RB WR TE DST K].freeze

        def min_args; 1; end
        def max_args; 4; end
        def channels; %w[testing].freeze end

        def description
          "Retrieves stats from www.westhoochington.com.".freeze
        end

        def usage
          "position [QB/RB/WR/TE/DST/K] [@user] [year] [week]".freeze
        end

        def user_total(position, user, event)
          discord_id = user.gsub(/\D+/, '')
          user_record = User.find_by(discord_id: discord_id)
          if user_record
            results = ratio_for_user(user_record, position)
            event << "#{user_record.random_nickname} has scored #{results[:percentage]}% of their lifetime points from the #{position} position (#{results[:position].round(2).to_s(:delimited)} / #{results[:total].round(2).to_s(:delimited)})."
          else
            event << "Sorry, but I did not recognize #{user}."
          end
        end

        def position_total(position, event)
          if VALID_POSITIONS.include?(position)
            position_points = PlayerGame.where(active: true, default_lineup_slot: position).all.sum(&:points)
            all_points = PlayerGame.where(active: true).all.sum(&:points)
            percentage = ((position_points / all_points) * 100).round(2)
            event << "A total of #{position_points.round(2).to_s(:delimited)} points have been scored at the #{position} position in league history."
            event << "This constitutes #{percentage}% of all #{all_points.round(2).to_s(:delimited)} points that have been scored in league history."
            event << "Here are all active league members sorted by the proportion of their points from the #{position} position:"
            active_users = User.where(active: true).all
            results = active_users.reduce([]) do |memo, user|
              results_for_user = ratio_for_user(user, position)
              if results_for_user[:total].zero?
                memo
              else
                memo + [results_for_user.merge(user: user.discord_mention)]
              end
            end.sort_by { |hash| -hash[:percentage] }
            results.each_with_index do |result, index|
              event << "#{index + 1}. #{result[:user]} -- #{result[:percentage]}% (#{result[:position].round(2).to_s(:delimited)} / #{result[:total].round(2).to_s(:delimited)})"
            end
          else
            event << "Invalid position #{position}. Must be one of #{VALID_POSITIONS.join(', ')}."
          end
        end

        def ratio_for_user(user, position, year = nil, week = nil)
          filter_conditions = { active: true, user_id: user.id, year: year, week: week }.compact
          total_points = PlayerGame.joins(:game).where(filter_conditions).all.sum(&:points)
          position_points = PlayerGame.joins(:game).where(filter_conditions.merge(default_lineup_slot: position)).all.sum(&:points)
          percentage = total_points.zero? ? 0.0 : ((position_points / total_points) * 100).round(2)
          { total: total_points, position: position_points, percentage: percentage }
        end
      end
    end
  end
end