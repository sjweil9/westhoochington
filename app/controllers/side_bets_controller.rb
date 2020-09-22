class SideBetsController < ApplicationController
  def index
    offset = Time.now.monday? ? 36 : 35
    @current_week = Time.now.strftime('%U').to_i - offset
    @current_games = Game.where(season_year: Date.today.year, week: @current_week).all
  end

  def pending

  end

  def resolved

  end
end
