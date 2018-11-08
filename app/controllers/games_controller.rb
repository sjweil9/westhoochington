class GamesController < ApplicationController
  def index
    @users = User.includes(user_joins).references(user_joins).all
  end

  def weekly_stats
    @weeks = (1..current_week).to_a
    @week = params[:week] == 'current' ? current_week : params[:week].to_i
    @users = User.includes(user_joins).references(user_joins).all
    @narrowest = Game.includes(game_joins).references(game_joins).where(week: @week).all.sort_by { |a| a.margin.abs }.first
  end

  private

  def current_week
    Time.now.strftime('%U').to_i - 34
  end

  def user_joins
    [{ games: :opponent }, :opponent_games, :nicknames]
  end

  def game_joins
    %i[user opponent]
  end
end
