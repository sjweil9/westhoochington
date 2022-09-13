module Discord
  module Messages
    class BestBallUpdateJob < ApplicationJob
      def perform(week)
        @week = week
        main_message = "**Best Ball Results for Week #{week} are in! Let's check in on the leagues:**\n"
        Discord::Channels::WeeklyWesthoochington.send_message(content: main_message)
        leagues.each do |league|
          content = "\n**#{league.name}**\n\n"
          content << "***Scores for the Week:***\n\n"
          ordered_weekly_games(league).each_with_index do |game, index|
            content << "#{game_content(game, index)}\n"
          end

          content << "\n\n***Current Standings:***\n\n"
          ordered_overall_players(league).each_with_index do |league_user, index|
            content << "#{league_user_content(league_user, index)}\n"
          end
          Discord::Channels::WeeklyWesthoochington.send_message(content: content)
        end
      end

      private

      attr_reader :week

      def leagues
        @leagues ||= BestBallLeague.where(season_year: Date.current.year).all
      end

      def ordered_weekly_games(league)
        BestBallGame.includes(:user).references(:user).where(best_ball_league: league, week: week).order(total_points: :desc).all
      end

      def ordered_overall_players(league)
        BestBallLeagueUser.includes(:user).references(:user).where(best_ball_league: league).order(total_points: :desc).all
      end

      def game_content(game, index)
        "#{index + 1}) #{game.user.random_nickname} -- #{game.total_points.round(2)}"
      end

      def league_user_content(league_user, index)
        "#{index + 1}) #{league_user.user.random_nickname} -- #{league_user.total_points.round(2)}"
      end
    end
  end
end