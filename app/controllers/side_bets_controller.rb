class SideBetsController < ApplicationController
  def index
    offset = Time.now.monday? ? 36 : 35
    @current_week = Time.now.strftime('%U').to_i - offset
    @current_year = Date.today.year
    @current_games = Game.unscoped.where(season_year: Date.today.year, week: @current_week).all.reject { |game| game.opponent_id > game.user_id }
  end

  def pending

  end

  def resolved

  end
end
