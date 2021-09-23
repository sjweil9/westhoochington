class BestBallGamesController < ApplicationController
  def index
    @year = params[:year] || most_recent_year
    @week = params[:week] == "season" ? nil : params[:week].to_i
    if @week
      @leagues = BestBallLeague.where(season_year: most_recent_year).all
      @games = BestBallGame.where(best_ball_league_id: @leagues.map(&:id), week: @week)
                 .includes(best_ball_includes)
                 .all
    else
      @leagues = BestBallLeague
                   .where(season_year: most_recent_year)
                   .includes(best_ball_includes)
                   .all
    end
  end

  private

  def most_recent_year
    ActiveRecord::Base.connection.execute("SELECT MAX(season_year) FROM best_ball_leagues;").values.flatten.first
  end

  def best_ball_includes
    [:user, lineup_ordered_players: :player]
  end
end
